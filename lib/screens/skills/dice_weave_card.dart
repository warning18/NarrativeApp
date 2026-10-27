import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../combat/dice_faces.dart' show dieDisplayName;
import '../../data/dice_weave.dart';
import '../../gamedata/db_schema.dart' show diceSchema;
import '../../l10n/app_locale.dart';
import '../../l10n/app_strings.dart';
import '../../providers/game_db_providers.dart' show localizedDbProvider;
import '../../providers/player_session_provider.dart';

/// The Skillwright's dice bench (dice_weave.dart): two d8s the player owns,
/// picked as chips, recut into the tally die. A plain card under the skill
/// recipes; its look is UX's to finish.
class DiceWeaveCard extends ConsumerStatefulWidget {
  const DiceWeaveCard({super.key});

  @override
  ConsumerState<DiceWeaveCard> createState() => _DiceWeaveCardState();
}

class _DiceWeaveCardState extends ConsumerState<DiceWeaveCard> {
  final _picked = <String>[];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    final session = ref.watch(playerSessionProvider);
    final dice = ref.watch(localizedDbProvider(diceSchema)).value ??
        const <String, dynamic>{};
    final weavable = weavableDice(session.ownedDiceIds, dice);
    _picked.removeWhere((id) => !weavable.contains(id));
    final owned = session.ownedDiceIds.contains(tallyDieId);
    final ready = _picked.length == 2 &&
        canWeaveDice(_picked[0], _picked[1],
            owned: session.ownedDiceIds,
            builtHouseIds: session.builtHouseIds,
            dice: dice);
    final note = owned
        ? tr(ref, 'weave_owned')
        : weavable.length < 2
            ? tr(ref, 'weave_need_two')
            : tr(ref, 'weave_intro');
    return Card(
      key: const Key('dice_weave_card'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr(ref, 'weave_title'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(note, style: theme.textTheme.bodySmall),
            if (!owned && weavable.length >= 2) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final id in weavable)
                    FilterChip(
                      key: Key('weave_pick_$id'),
                      label: Text(dieDisplayName(id, language: lang)),
                      selected: _picked.contains(id),
                      onSelected: (on) => setState(() {
                        if (!on) {
                          _picked.remove(id);
                        } else if (_picked.length < 2) {
                          _picked.add(id);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('weave_button'),
                onPressed: ready
                    ? () async {
                        final pair = [..._picked];
                        setState(_picked.clear);
                        await ref
                            .read(playerSessionProvider.notifier)
                            .weaveDice(pair[0], pair[1], dice: dice);
                      }
                    : null,
                child: Text(tr(ref, 'weave_button')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
