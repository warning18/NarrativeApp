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
import '../../utils/face_style.dart';
import '../../widgets/ink_panel.dart';
import '../../widgets/die_3d.dart';
import 'ink/ink_dice.dart';
import 'ink/ink_kit.dart';
import 'ink/ink_palette.dart';

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
                          decoration: BoxDecoration(
                            color: d.inPlay ? inkDeep : Colors.transparent,
                            border: Border.all(
                              color: _open == d.id
                                  ? inkPaper
                                  : d.inPlay
                                      ? inkRed
                                      : inkSlate,
                              width: _open == d.id || d.inPlay ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _InkDie(d, lit: d.inPlay || d.resonates),
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
                                          decoration: const BoxDecoration(
                                            color: inkRed,
                                            shape: BoxShape.circle,
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
                                  inkRed,
                                  theme,
                                ),
                              if (d.resonates)
                                _tag(
                                  tr(ref, 'tower_dice_resonates'),
                                  inkPaper,
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
          // The faces of the die shown, one chip each in a single strip: the
          // opened die's, else the die in play's (v1.1005).
          if (open ?? widget.dice.where((d) => d.inPlay).firstOrNull
              case final shown?) ...[
            const SizedBox(height: 10),
            Row(
              key: const Key('tower_die_strip'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (final f in shown.faces) _face(f, theme)],
            ),
          ],
          if (open != null) ...[
            const SizedBox(height: 10),
            InkButton(
              buttonKey: const Key('tower_die_roll'),
              onPressed: open.inPlay ? null : () => widget.onChoose(open.id),
              primary: true,
              label: open.inPlay
                  ? tr(ref, 'tower_dice_in_play')
                  : tr(ref, 'tower_dice_roll'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _face(Map<String, dynamic> face, ThemeData theme) {
    final kind = faceKind('${face['type']}');
    final value = face['value'];
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        decoration:
            BoxDecoration(border: Border.all(color: inkGrey), color: inkDeep),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(kind.icon, size: IconSize.s16, color: inkPaper),
              if (value != null) ...[
                const SizedBox(width: 2),
                Text('$value', style: theme.textTheme.labelMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color color, ThemeData theme) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: inkBlack,
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(color: inkPaper),
            ),
          ),
        ),
      );
}

/// The die as a real solid in ink (v1.1005), each face its own kind's mark; the
/// die in play (or resonating) wears the red edge.
class _InkDie extends StatelessWidget {
  const _InkDie(this.die, {required this.lit});

  final TowerDieView die;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final n = die.faces.length;
    DieCubeFace face(int i) {
      final f = die.faces[i % n];
      final kind = faceKind('${f['type']}');
      return DieCubeFace(
          glyph: Icon(kind.icon,
              size: IconSize.s16, color: lit ? inkPaper : inkGrey),
          color: lit && i == 0 ? inkRed : inkGrey);
    }

    final shape = dieShapeOf(n);
    return Die3D(
      faces: [for (var i = 0; i < 6; i++) face(i)],
      facets:
          shape == DieShape.d6 ? null : [for (var i = 0; i < n; i++) face(i)],
      accent: inkGrey,
      size: 48,
      shape: shape,
      skin: lit ? inkDieSkinLit : inkDieSkin,
      still: true,
      element: 'None',
    );
  }
}
