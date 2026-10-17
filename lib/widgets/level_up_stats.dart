// The stats a level's points are spent on (v1.258): four groups of
// seam-bordered rows, each with its icon, its value in gold and a "+1
// Point". A tap or a long press on a row says what the stat does. The Level
// Up screen and the pop-up after a fight both show them, so they read alike.
// Since v1.475 they open as the ability radar (a tap on a corner says where
// it comes from), the fight numbers under it, and a Detail tab that opens the
// list of rows.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart';
import 'ability_radar.dart';
import 'detail_dialog.dart';
import 'stat_sheet.dart';

class LevelUpStats extends ConsumerStatefulWidget {
  const LevelUpStats({super.key, this.tutorialTargets = false});

  /// Marks the stats for the Level Up screen's tour.
  final bool tutorialTargets;

  @override
  ConsumerState<LevelUpStats> createState() => _LevelUpStatsState();
}

class _LevelUpStatsState extends ConsumerState<LevelUpStats> {
  /// The Detail tab: the whole list under the radar.
  bool _detail = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);

    Widget row(String labelKey, IconData icon, String value, String statKey,
            String descKey) =>
        _StatRow(
          label: tr(ref, labelKey),
          icon: icon,
          value: value,
          statKey: statKey,
          description: tr(ref, descKey),
          closeLabel: tr(ref, 'close_button'),
          plusLabel: tr(ref, 'plus_one_point'),
          // Points go to stat picks now (stat_pick_picker.dart).
          onSpend: null,
        );

    // What the eight abilities add up to in a fight, in a line under the
    // radar: the radar only draws the abilities.
    Widget fighting(String key, IconData icon, String value, String label) =>
        Expanded(
          child: Column(
            key: Key(key),
            children: [
              Icon(icon, size: 18, color: ink.gold),
              const SizedBox(height: 2),
              Text(value,
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontFamily: InkFonts.display, color: ink.gold)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
            ],
          ),
        );

    final radar = Column(
      children: [
        Center(
          child: AbilityRadar(
            key: const Key('level_up_radar'),
            size: 230,
            t: (key) => tr(ref, key),
            values: {
              'strength': session.strength,
              'dexterity': session.dexterity,
              'constitution': session.constitution,
              'intelligence': session.intelligence,
              'wisdom': session.wisdom,
              'perception': session.perception,
              'luck': session.luck,
              'charisma': session.charisma,
            },
            onAxisTap: (ability) => showStatSheet(context, ability),
          ),
        ),
        // The corner labels hang below the radar's own box.
        const SizedBox(height: 14),
        Text(tr(ref, 'stat_radar_hint'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fighting('level_up_fight_damage', Icons.gavel,
                '${session.baseDamage}', tr(ref, 'base_damage_label')),
            fighting('level_up_fight_armor', Icons.shield,
                '${session.baseArmor}', tr(ref, 'base_armor_label')),
            fighting(
                'level_up_fight_health',
                Icons.favorite,
                '${session.currentHealth}/${session.maxHealth}',
                tr(ref, 'max_health_label')),
          ],
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.tutorialTargets
            ? TutorialTarget(id: 'levelUp.stats', child: radar)
            : radar,
        const SizedBox(height: 10),
        // The Detail tab under the radar: it opens the list.
        Material(
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: _detail ? ink.gold : ink.seam),
          ),
          child: InkWell(
            key: const Key('level_up_detail_tab'),
            borderRadius: BorderRadius.circular(4),
            onTap: () => setState(() => _detail = !_detail),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(tr(ref, 'level_stats_detail'),
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontFamily: InkFonts.system)),
                  ),
                  Icon(_detail ? Icons.expand_less : Icons.expand_more,
                      color: _detail ? ink.gold : ink.ash),
                ],
              ),
            ),
          ),
        ),
        if (_detail) ...[
          const SizedBox(height: 12),
          _Caption(tr(ref, 'level_group_fighting'), first: true),
          row('base_damage_label', Icons.gavel, '${session.baseDamage}',
              'damage', 'base_damage_desc'),
          row('base_armor_label', Icons.shield, '${session.baseArmor}', 'armor',
              'base_armor_desc'),
          row(
              'max_health_label',
              Icons.favorite,
              '${session.currentHealth} / ${session.maxHealth}',
              'health',
              'max_health_desc'),
          _Caption(tr(ref, 'level_group_body')),
          row('strength_label', Icons.fitness_center, '${session.strength}',
              'strength', 'strength_desc'),
          row('dexterity_label', Icons.directions_run, '${session.dexterity}',
              'dexterity', 'dexterity_desc'),
          row('constitution_label', Icons.health_and_safety,
              '${session.constitution}', 'constitution', 'constitution_desc'),
          _Caption(tr(ref, 'level_group_mind')),
          row('intelligence_label', Icons.psychology, '${session.intelligence}',
              'intelligence', 'intelligence_desc'),
          row('wisdom_label', Icons.visibility, '${session.wisdom}', 'wisdom',
              'wisdom_desc'),
          row('perception_label', Icons.radar, '${session.perception}',
              'perception', 'perception_desc'),
          _Caption(tr(ref, 'level_group_fortune')),
          row('luck_label', Icons.auto_awesome, '${session.luck}', 'luck',
              'luck_desc'),
          row('charisma_label', Icons.forum, '${session.charisma}', 'charisma',
              'charisma_desc'),
        ],
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text, {this.first = false});

  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 18, bottom: 6),
      child: Text(text.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: ink.ash, letterSpacing: 1.2)),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.statKey,
    required this.description,
    required this.closeLabel,
    required this.plusLabel,
    required this.onSpend,
  });

  final String label;
  final IconData icon;
  final String value;
  final String statKey;
  final String description;
  final String closeLabel;
  final String plusLabel;
  final VoidCallback? onSpend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    void explain() => showDetailDialog(
          context,
          title: label,
          description: description,
          icon: icon,
          closeLabel: closeLabel,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: ink.seam),
        ),
        child: InkWell(
          key: Key('stat_row_$statKey'),
          borderRadius: BorderRadius.circular(4),
          onTap: explain,
          onLongPress: explain,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ink.seam),
                  ),
                  child: Icon(icon, size: 18, color: ink.gold),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontFamily: InkFonts.system)),
                ),
                Text(value,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: InkFonts.display, color: ink.gold)),
                if (onSpend != null) ...[
                  const SizedBox(width: 10),
                  FilledButton(
                    // The value on the row goes up; no message on top of it.
                    onPressed: onSpend,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text(plusLabel),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
