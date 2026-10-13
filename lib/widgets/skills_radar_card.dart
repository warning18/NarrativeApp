// The Character tab's top card (v1.266): the skills known, a few of them
// with their icon, beside a small radar of the eight abilities.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../screens/skills/skill_sheet.dart';
import '../screens/skills/skills_screen.dart';
import '../combat/dice_faces.dart' show skillDisplayName;
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'ability_radar.dart';

/// How many skills the card lists before "All skills".
const int skillsCardRows = 5;

class SkillsRadarCard extends ConsumerWidget {
  const SkillsRadarCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final model = watchSkillsModel(ref, null);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final known = model?.knownIds ?? const <String>[];
    final shown = known.take(skillsCardRows).toList();
    final abilities = <String, int>{
      'strength': session.strength,
      'dexterity': session.dexterity,
      'constitution': session.constitution,
      'intelligence': session.intelligence,
      'wisdom': session.wisdom,
      'perception': session.perception,
      'luck': session.luck,
      'charisma': session.charisma,
    };

    void openSkills() => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SkillsScreen()));

    Widget skill(String id) => InkWell(
          key: Key('character_skill_$id'),
          onTap: () => showSkillSheet(context, id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ink.seam),
                  ),
                  child: SkillPixelIcon(id, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(skillDisplayName(id, language: lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        );

    return Material(
      key: const Key('character_skills_card'),
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: ink.seam),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(tr(ref, 'skills').toUpperCase(),
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: ink.gold, letterSpacing: 1.2)),
                ),
                InkWell(
                  key: const Key('character_skills_all'),
                  onTap: openSkills,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('${tr(ref, 'skills_see_all')} ›',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: ink.ash)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: shown.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(tr(ref, 'skills_none_short'),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: ink.ash)),
                        )
                      : Column(children: [for (final id in shown) skill(id)]),
                ),
                const SizedBox(width: 4),
                Semantics(
                  container: true,
                  child: AbilityRadar(
                    key: const Key('character_radar'),
                    size: 170,
                    compact: true,
                    t: (key) => tr(ref, key),
                    values: abilities,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
