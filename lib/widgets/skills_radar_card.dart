// The Character page's Overview (v1.267): one radar in a card with a switch
// under it (v1.740): the eight abilities, the skills known by element, or the
// detail behind both: the numbers, a bar per element and the skills as chips,
// a tap on one reading it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/dice_faces.dart' show skillDisplayName;
import '../data/element_points.dart' show chartScaleFor, elementChartOrder;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../screens/skills/skill_sheet.dart';
import '../screens/skills/skills_screen.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'ability_radar.dart';
import 'radar_chart.dart';
import 'stat_sheet.dart';
import 'feature_unlock.dart';
import '../theme/icon_sizes.dart';

/// How many skills the Detail view lists before "All skills".
const int _skillsCardRows = 6;

/// Which view of the card is shown.
enum _RadarView { abilities, skills, detail }

/// The known skills of each element ('None' has no axis).
Map<String, int> skillsByElement(Iterable<Map<String, dynamic>> records) {
  final counts = {for (final e in elementChartOrder) e: 0};
  for (final record in records) {
    final element = record['element']?.toString();
    if (counts.containsKey(element)) counts[element!] = counts[element]! + 1;
  }
  return counts;
}

class SkillsRadarCard extends ConsumerStatefulWidget {
  const SkillsRadarCard({super.key});

  @override
  ConsumerState<SkillsRadarCard> createState() => _SkillsRadarCardState();
}

class _SkillsRadarCardState extends ConsumerState<SkillsRadarCard> {
  _RadarView _view = _RadarView.abilities;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider);
    final model = watchSkillsModel(ref, null);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final known = model?.knownIds ?? const <String>[];
    final shown = known.take(_skillsCardRows).toList();
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

    void openSkills() {
      acknowledgeOnOpen(ref, GameFeature.skills);
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SkillsScreen()));
    }

    Widget skill(String id, double width) => SizedBox(
          width: width,
          child: Material(
            color: theme.colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: ink.seam),
            ),
            child: InkWell(
              key: Key('character_skill_$id'),
              borderRadius: BorderRadius.circular(4),
              onTap: () => showSkillSheet(context, id),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: ink.seam),
                      ),
                      child: SkillPixelIcon(id, size: IconSize.s16),
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
            ),
          ),
        );

    final unlocked = isFeatureUnlocked(ref, GameFeature.skills.id);
    // A locked Skills page has nothing to show: the card stays on the
    // abilities, with no switch.
    final view = unlocked ? _view : _RadarView.abilities;
    final byElement = skillsByElement([
      for (final id in known) model?.entries[id]?.record ?? const {},
    ]);

    String elementName(String element) => element == 'Electricity'
        ? tr(ref, 'element_short_electricity')
        : tr(ref, 'element_name_${element.toLowerCase()}');

    Widget skillsRadar() {
      final highest = byElement.values.fold(0, (m, v) => v > m ? v : m);
      return Center(
        child: RadarChart(
          key: const Key('character_skills_radar'),
          size: 250,
          max: chartScaleFor(highest, floor: 4, step: 2),
          axes: [
            for (final e in elementChartOrder)
              RadarAxis(label: elementName(e), value: '${byElement[e]}'),
          ],
          layers: [
            RadarLayer(values: [
              for (final e in elementChartOrder) byElement[e]! + 0.0
            ], color: radarGold),
          ],
          semanticsLabel: [
            for (final e in elementChartOrder)
              '${elementName(e)} ${byElement[e]}'
          ].join(', '),
        ),
      );
    }

    Widget bar(String label, int value, int highest) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: highest == 0 ? 0 : value / highest,
                    minHeight: 8,
                    backgroundColor: ink.seam,
                    color: radarGold,
                  ),
                ),
              ),
              SizedBox(
                width: 28,
                child: Text('$value',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
          child: Text(text.toUpperCase(),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: ink.gold, letterSpacing: 1.2)),
        );

    Widget detail() {
      final top = abilities.values.fold(0, (m, v) => v > m ? v : m);
      final topElement = byElement.values.fold(0, (m, v) => v > m ? v : m);
      return Padding(
        key: const Key('character_radar_detail'),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading(tr(ref, 'abilities_label')),
            for (final k in abilityRadarOrder)
              InkWell(
                onTap: () => showStatSheet(context, k),
                child:
                    bar(tr(ref, abilityAbbrevKey(k)), abilities[k] ?? 0, top),
              ),
            heading(tr(ref, 'skills')),
            if (known.isEmpty)
              Text(tr(ref, 'skills_none_short'),
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash))
            else ...[
              for (final e in elementChartOrder)
                if (byElement[e]! > 0)
                  bar(elementName(e), byElement[e]!, topElement),
              const SizedBox(height: 8),
              LayoutBuilder(builder: (context, box) {
                final width = (box.maxWidth - 6) / 2;
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final id in shown) skill(id, width)],
                );
              }),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  key: const Key('character_skills_all'),
                  onTap: openSkills,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text('${tr(ref, 'skills_see_all')} ›',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: ink.ash)),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          key: const Key('character_skills_card'),
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: ink.seam),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                if (unlocked)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                    child: SegmentedButton<_RadarView>(
                      key: const Key('character_radar_views'),
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 4)),
                      ),
                      segments: [
                        ButtonSegment(
                            value: _RadarView.abilities,
                            label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(tr(ref, 'abilities_label'),
                                    key: const Key('character_view_abilities'),
                                    maxLines: 1))),
                        ButtonSegment(
                            value: _RadarView.skills,
                            label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(tr(ref, 'skills'),
                                    key: const Key('character_view_skills'),
                                    maxLines: 1))),
                        ButtonSegment(
                            value: _RadarView.detail,
                            label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(tr(ref, 'radar_view_detail'),
                                    key: const Key('character_view_detail'),
                                    maxLines: 1))),
                      ],
                      selected: {view},
                      onSelectionChanged: (picked) =>
                          setState(() => _view = picked.first),
                    ),
                  ),
                if (view == _RadarView.abilities) ...[
                  Center(
                    child: AbilityRadar(
                      key: const Key('character_radar'),
                      size: 250,
                      t: (key) => tr(ref, key),
                      values: abilities,
                      onAxisTap: (ability) => showStatSheet(context, ability),
                    ),
                  ),
                  // The corner labels hang below the radar's own box.
                  const SizedBox(height: 14),
                  Text(tr(ref, 'stat_radar_hint'),
                      key: const Key('character_radar_hint'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: ink.ash, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 4),
                ] else if (view == _RadarView.skills) ...[
                  skillsRadar(),
                  const SizedBox(height: 14),
                  Text(
                      known.isEmpty
                          ? tr(ref, 'skills_none_short')
                          : tr(ref, 'skills_radar_hint'),
                      key: const Key('character_skills_radar_hint'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: ink.ash, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 4),
                ] else
                  detail(),
              ],
            ),
          ),
        ),
        if (!unlocked) ...[
          const SizedBox(height: 12),
          const FeatureLockedTile(feature: GameFeature.skills),
        ],
      ],
    );
  }
}
