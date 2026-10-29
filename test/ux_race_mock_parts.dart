// The drawing of the race and profession mock (ux_race_mock_test.dart): the
// proposed choice screen built from the real races, professions, skill
// trees and clans, with placeholder "way of playing" lines (Narrative's to
// write). Mock only; nothing here ships.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:narrative_data_app/combat/dice_faces.dart'
    show skillDisplayName;
import 'package:narrative_data_app/data/clan_affinity.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/skill_tree.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/screens/race_profession_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

/// Narrative's `playstyle` lines (v1.598, PR #566), kept here until that
/// field is on main; the cards read the record's own `playstyle` first.
const Map<String, String> wayOfPlaying = {
  'dwarf': 'Hard to kill: extra life, armor and a stone-skin heal',
  'elf': 'Quick and lucky, strikes sharp; fragile if caught',
  'human': 'Coin and charm first; a small heal when pressed',
  'orc': 'Raw strength and a rage strike; poor talker',
  'voidkin': 'Sharp-minded but brittle; the Shroud shields it',
  'warrior': 'Front line: soaks hits, stuns with the shield',
  'mage': 'Casts from mana: bolts and wards; weak up close',
  'rogue': 'Fast and lucky: a backstab that weakens the foe',
  'cleric': 'Heals and purges, sturdy in a fight; prayer for mana',
  'ranger': 'Takes careful aim for sharp shots; no extra life',
};

/// The one line on how [id] plays: the record's own, else the line above.
String playstyleOf(Map<String, dynamic> record, String id) =>
    record['playstyle']?.toString() ?? wayOfPlaying[id] ?? '';

const List<(String, String)> _bonusFields = [
  ('bonusMaxHealth', 'HP'),
  ('bonusBaseDamage', 'DMG'),
  ('bonusBaseArmor', 'ARM'),
  ('bonusStrength', 'STR'),
  ('bonusDexterity', 'DEX'),
  ('bonusConstitution', 'CON'),
  ('bonusIntelligence', 'INT'),
  ('bonusWisdom', 'WIS'),
  ('bonusPerception', 'PER'),
  ('bonusLuck', 'LUCK'),
  ('bonusCharisma', 'CHA'),
];

/// The [max] strongest bonuses of [record], by size: (label, value).
List<(String, int)> statChips(Map<String, dynamic> record, {int max = 4}) {
  final all = [
    for (final (field, label) in _bonusFields)
      if (((record[field] as num?)?.toInt() ?? 0) != 0)
        (label, (record[field] as num).toInt()),
    if (((record['startingGoldBonus'] as num?)?.toInt() ?? 0) != 0)
      ('gold', (record['startingGoldBonus'] as num).toInt()),
  ]..sort((a, b) => b.$2.abs().compareTo(a.$2.abs()));
  return all.take(max).toList();
}

/// What the choice reads: its records and the clans behind each.
class Choices {
  Choices({
    required this.races,
    required this.professions,
    required this.trees,
    required this.data,
  }) : matrix = buildAffinityMatrix(
          data: data,
          skillTrees: trees,
          raceIds: races.keys.toList()..sort(),
          professionIds: professions.keys.toList()..sort(),
        );

  final Map<String, dynamic> races;
  final Map<String, dynamic> professions;
  final Map<String, dynamic> trees;
  final ClanData data;
  final ClanAffinityMatrix matrix;

  Map<String, dynamic> raceOf(String id) => races[id] as Map<String, dynamic>;
  Map<String, dynamic> professionOf(String id) =>
      professions[id] as Map<String, dynamic>;

  List<String> clansOf(String folder, String id) =>
      folder == 'races' ? matrix.clansOfRace(id) : matrix.clansOfProfession(id);

  /// The branches the choice opens: a race's heritage, a class's three.
  List<SkillBranch> branchesOf(String folder, String id) => [
        for (final e in trees.entries)
          if (e.value is Map<String, dynamic> &&
              (folder == 'races'
                  ? (e.value['raceId']?.toString() ?? '') == id
                  : (e.value['professionId']?.toString() ?? '') == id))
            SkillBranch.fromRecord(e.key, e.value as Map<String, dynamic>),
      ]..sort((a, b) => a.order.compareTo(b.order));

  /// The clan that sponsors [branch], if one does.
  Faction? sponsorOf(SkillBranch branch) {
    for (final f in data.clans) {
      if (f.sponsors.contains(branch.id)) return f;
    }
    return null;
  }

  /// The clans that will come first to a [raceId] [professionId]: those
  /// behind both, then those behind more of the class's branches.
  List<String> firstCourtiers(String raceId, String professionId) {
    final byRace = matrix.clansOfRace(raceId).toSet();
    final ids = {...byRace, ...matrix.clansOfProfession(professionId)};
    int score(String c) =>
        (byRace.contains(c) ? 1 : 0) + matrix.professionLevel(c, professionId);
    return ids.toList()
      ..sort((a, b) {
        final s = score(b).compareTo(score(a));
        return s != 0 ? s : a.compareTo(b);
      });
  }
}

class WithChoices extends ConsumerWidget {
  const WithChoices(this.builder, {super.key});
  final Widget Function(BuildContext, WidgetRef, Choices) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final races = ref.watch(localizedDbProvider(racesSchema)).value;
    final professions = ref.watch(localizedDbProvider(professionsSchema)).value;
    final trees = ref.watch(localizedDbProvider(skillTreesSchema)).value;
    if (races == null || professions == null || trees == null) {
      return const SizedBox.shrink();
    }
    return builder(
        context,
        ref,
        Choices(
          races: races,
          professions: professions,
          trees: trees,
          data: ref.watch(clanDataProvider),
        ));
  }
}

String shortOf(Faction f) => f.shortFor(AppLanguage.en);
String nameOf(Faction f) => f.nameFor(AppLanguage.en);

/// A phone: app bar, body.
class Phone extends StatelessWidget {
  const Phone({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.title = 'Race & Profession',
    this.bare = false,
  });
  final double width;
  final double height;
  final String title;
  final bool bare;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border.all(color: const Color(0xFF3A3642), width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: bare
            ? child
            : Column(children: [
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: InkColors.of(context).seam)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Text(title,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontFamily: InkFonts.display)),
                    ),
                    Icon(Icons.casino_outlined,
                        size: 22, color: theme.colorScheme.onSurface),
                  ]),
                ),
                Expanded(child: ClipRect(child: child)),
              ]),
      ),
    );
  }
}

/// A clan as a small disc: its banner on its colour.
class ClanDisc extends StatelessWidget {
  const ClanDisc(this.faction, {super.key, this.size = 30, this.name = false});
  final Faction faction;
  final double size;
  final bool name;

  @override
  Widget build(BuildContext context) {
    final colour = Color(faction.color);
    final disc = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colour.withValues(alpha: 0.14),
        border: Border.all(color: colour, width: 1.6),
      ),
      child: ClanFlag(factionId: faction.id, height: size * 0.66),
    );
    if (!name) return disc;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      disc,
      const SizedBox(width: 6),
      Text(shortOf(faction),
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: colour, fontWeight: FontWeight.w600)),
    ]);
  }
}

Widget statChip(BuildContext context, String label, int value) {
  final theme = Theme.of(context);
  final good = value > 0;
  final colour = good ? const Color(0xFF3F8F5A) : const Color(0xFFC0392B);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: colour.withValues(alpha: 0.1),
      border: Border.all(color: colour.withValues(alpha: 0.6)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text('${good ? '+' : ''}$value $label',
        style: theme.textTheme.labelMedium?.copyWith(color: colour)),
  );
}

/// One choice as a card: its mark, name and tag, the way of playing in one
/// line, a few stat chips, the clans behind it.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.choices,
    required this.folder,
    required this.id,
    this.selected = false,
    this.compact = false,
    this.picked = false,
  });

  final Choices choices;
  final String folder;
  final String id;
  final bool selected;

  /// One slim line (the other choices once one is open).
  final bool compact;
  final bool picked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final record =
        folder == 'races' ? choices.raceOf(id) : choices.professionOf(id);
    final name =
        (record[folder == 'races' ? 'raceName' : 'professionName'] ?? id)
            .toString();
    final tag = record['tag']?.toString() ?? '';
    final clans = [
      for (final c in choices.clansOf(folder, id))
        if (choices.data.faction(c) case final f?) f,
    ];
    final border = selected ? ink.gold : ink.seam;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.fromLTRB(10, compact ? 7 : 10, 10, compact ? 7 : 10),
      decoration: BoxDecoration(
        color: selected
            ? ink.gold.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: selected ? 2 : 1),
      ),
      child: Row(children: [
        PresetMark(folder: folder, preset: record, size: compact ? 30 : 44),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontFamily: InkFonts.display)),
                const SizedBox(width: 8),
                if (tag.isNotEmpty) InkTag(label: tag, color: ink.gold),
              ]),
              Text(playstyleOf(record, id),
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
              if (!compact) ...[
                const SizedBox(height: 6),
                Wrap(spacing: 4, runSpacing: 4, children: [
                  for (final (label, value) in statChips(record))
                    statChip(context, label, value),
                ]),
              ],
            ],
          ),
        ),
        const SizedBox(width: 6),
        // The clans behind it, small.
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Wrap(
              spacing: -6,
              children: [
                for (final f in clans.take(compact ? 3 : 4))
                  ClanDisc(f, size: compact ? 22 : 26),
              ],
            ),
            if (!compact)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('${clans.length} clans',
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
              ),
          ],
        ),
        if (picked)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(Icons.check_circle, color: ink.gold, size: 20),
          ),
      ]),
    );
  }
}

/// What the open choice tells: the clans that will court you, and what it
/// unlocks.
class OpenChoice extends StatelessWidget {
  const OpenChoice({
    super.key,
    required this.choices,
    required this.folder,
    required this.id,
  });
  final Choices choices;
  final String folder;
  final String id;

  /// One row per clan: a people's clans each say they sponsor its heritage;
  /// a calling's clans each offer one of its branches.
  List<Widget> clanRows(BuildContext context, List<SkillBranch> branches) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final rows = <(Faction, String)>[];
    if (folder == 'races') {
      for (final c in choices.clansOf(folder, id)) {
        final f = choices.data.faction(c);
        if (f != null) {
          rows.add((
            f,
            'Sponsors your heritage: ${branches.map((b) => b.name).join(', ')}'
          ));
        }
      }
    } else {
      for (final b in branches) {
        final f = choices.sponsorOf(b);
        if (f != null) rows.add((f, 'Offers the ${b.name} branch'));
      }
    }
    return [
      for (final (f, line) in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            ClanDisc(f, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nameOf(f),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: Color(f.color))),
                  Text(line,
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: ink.ash),
          ]),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final record =
        folder == 'races' ? choices.raceOf(id) : choices.professionOf(id);
    final branches = choices.branchesOf(folder, id);
    final standard = record['standardSkillID']?.toString() ?? '';
    final lines = <(IconData, String)>[
      if (folder == 'races') ...[
        (
          Icons.account_tree_outlined,
          'Heritage branch: ${branches.map((b) => b.name).join(', ')}'
        ),
        (Icons.brush_outlined, 'Power medium: ${record['powerMedium'] ?? ''}'),
      ] else ...[
        (
          Icons.account_tree_outlined,
          'Three branches: ${branches.map((b) => b.name).join(' · ')}'
        ),
        if ((record['preferredScalingStat']?.toString() ?? '').isNotEmpty)
          (
            Icons.trending_up,
            'Its gear scales with ${record['preferredScalingStat']}'
          ),
        if (((record['startingSpellIds'] as List?) ?? const []).isNotEmpty)
          (Icons.auto_awesome, 'Starts with a die and two spells'),
      ],
      if (standard.isNotEmpty)
        (Icons.bolt, 'Starting skill: ${skillDisplayName(standard)}'),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ink.seam),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THESE CLANS WILL COURT YOU',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: ink.ash, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          ...clanRows(context, branches),
          const Divider(height: 18),
          Text('IT UNLOCKS',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: ink.ash, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          for (final (icon, text) in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon, size: 16, color: ink.gold),
                const SizedBox(width: 8),
                Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
              ]),
            ),
        ],
      ),
    );
  }
}

/// The two steps as a switch, each with what is picked.
class StepSwitch extends StatelessWidget {
  const StepSwitch({
    super.key,
    required this.choices,
    required this.raceId,
    required this.professionId,
    required this.step,
  });
  final Choices choices;
  final String? raceId;
  final String? professionId;
  final int step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    Widget seg(int i, String label, String? id, String folder) {
      final on = step == i;
      final record = id == null
          ? null
          : (folder == 'races' ? choices.raceOf(id) : choices.professionOf(id));
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: on ? ink.gold.withValues(alpha: 0.14) : null,
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: on ? ink.gold : ink.seam, width: on ? 2 : 1),
          ),
          child: Row(children: [
            if (record != null)
              PresetMark(folder: folder, preset: record, size: 28)
            else
              Icon(Icons.help_outline, size: 26, color: ink.ash),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: ink.ash, letterSpacing: 1)),
                  Text(
                      record == null
                          ? 'Choose'
                          : (record[folder == 'races'
                                      ? 'raceName'
                                      : 'professionName'] ??
                                  id)
                              .toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: record == null ? ink.ash : null)),
                ],
              ),
            ),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(children: [
        seg(0, '1 · People', raceId, 'races'),
        const SizedBox(width: 8),
        seg(1, '2 · Calling', professionId, 'professions'),
      ]),
    );
  }
}

/// The picker's body: a step's cards, the open one told in full.
class PickerBody extends StatelessWidget {
  const PickerBody({
    super.key,
    required this.step,
    this.raceId,
    this.professionId,
    this.open = false,
    this.showSummary = false,
  });

  /// 0 the peoples, 1 the callings.
  final int step;
  final String? raceId;
  final String? professionId;

  /// Whether the picked card of this step is open.
  final bool open;
  final bool showSummary;

  @override
  Widget build(BuildContext context) {
    return WithChoices((context, ref, choices) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      final folder = step == 0 ? 'races' : 'professions';
      final ids =
          ((step == 0 ? choices.races : choices.professions).keys.toList()
                ..sort())
              .cast<String>();
      final pickedHere = step == 0 ? raceId : professionId;
      final both = raceId != null && professionId != null;
      return Column(children: [
        StepSwitch(
            choices: choices,
            raceId: raceId,
            professionId: professionId,
            step: step),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            children: [
              if (pickedHere == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                          step == 0
                              ? 'Who are your people? The clans behind them will court you.'
                              : 'How will you fight? Your calling opens three branches of skills.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: ink.ash)),
                    ),
                    const SizedBox(width: 8),
                    pill(context, 'Compare', ink.tide, Icons.compare_arrows),
                  ]),
                ),
              if (open && pickedHere != null) ...[
                ChoiceCard(
                    choices: choices,
                    folder: folder,
                    id: pickedHere,
                    selected: true),
                OpenChoice(choices: choices, folder: folder, id: pickedHere),
                for (final id in ids)
                  if (id != pickedHere)
                    ChoiceCard(
                        choices: choices,
                        folder: folder,
                        id: id,
                        compact: true),
              ] else
                for (final id in ids)
                  ChoiceCard(
                      choices: choices,
                      folder: folder,
                      id: id,
                      selected: id == pickedHere),
            ],
          ),
        ),
        if (showSummary && both)
          SummaryCard(
              choices: choices, raceId: raceId!, professionId: professionId!),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: both ? () {} : null,
              icon: const Icon(Icons.play_arrow),
              label: Text(both
                  ? 'Start new game'
                  : pickedHere == null
                      ? 'Pick ${step == 0 ? 'a people' : 'a calling'}'
                      : 'Now pick ${step == 0 ? 'a calling' : 'a people'}'),
            ),
          ),
        ),
      ]);
    });
  }
}

Widget pill(BuildContext context, String text, Color colour, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: colour),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: colour),
      const SizedBox(width: 4),
      Text(text,
          style:
              Theme.of(context).textTheme.labelMedium?.copyWith(color: colour)),
    ]),
  );
}

/// After both picks: who you will play as, and who will come first.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.choices,
    required this.raceId,
    required this.professionId,
  });
  final Choices choices;
  final String raceId;
  final String professionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final race = choices.raceOf(raceId);
    final profession = choices.professionOf(professionId);
    final first = [
      for (final c in choices.firstCourtiers(raceId, professionId))
        if (choices.data.faction(c) case final f?) f,
    ];
    final both = [
      for (final c in choices.matrix.clansOfRace(raceId))
        if (choices.matrix.professionLevel(c, professionId) > 0) c
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: ink.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ink.gold, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOU WILL PLAY AS',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: ink.gold, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Row(children: [
            PresetMark(folder: 'races', preset: race, size: 32),
            PresetMark(folder: 'professions', preset: profession, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  'A ${race['raceName']} ${profession['professionName']}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontFamily: InkFonts.display)),
            ),
          ]),
          Text(playstyleOf(profession, professionId),
              style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
          const SizedBox(height: 8),
          Text(
              both.isEmpty
                  ? 'THE CLANS THAT WILL COME FIRST'
                  : 'THE CLANS THAT WILL COME FIRST · ${both.length} BACK BOTH',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: ink.ash, letterSpacing: 1)),
          const SizedBox(height: 6),
          Wrap(spacing: 10, runSpacing: 6, children: [
            for (final f in first.take(3)) ClanDisc(f, size: 28, name: true),
          ]),
        ],
      ),
    );
  }
}

/// Two callings (or peoples) side by side.
class CompareSheet extends StatelessWidget {
  const CompareSheet(
      {super.key, required this.folder, required this.a, required this.b});
  final String folder;
  final String a;
  final String b;

  @override
  Widget build(BuildContext context) {
    return WithChoices((context, ref, choices) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      Widget column(String id) {
        final record =
            folder == 'races' ? choices.raceOf(id) : choices.professionOf(id);
        final branches = choices.branchesOf(folder, id);
        final clans = [
          for (final c in choices.clansOf(folder, id))
            if (choices.data.faction(c) case final f?) f,
        ];
        return Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: PresetMark(folder: folder, preset: record, size: 44)),
            const SizedBox(height: 4),
            Center(
              child: Text(
                  (record[folder == 'races' ? 'raceName' : 'professionName'] ??
                          id)
                      .toString(),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontFamily: InkFonts.display)),
            ),
            Center(
                child: InkTag(
                    label: record['tag']?.toString() ?? '', color: ink.gold)),
            const SizedBox(height: 8),
            Text(playstyleOf(record, id),
                style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
            const SizedBox(height: 8),
            Wrap(spacing: 4, runSpacing: 4, children: [
              for (final (label, value) in statChips(record, max: 6))
                statChip(context, label, value),
            ]),
            const SizedBox(height: 10),
            Text('BRANCHES',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: ink.ash, letterSpacing: 1)),
            for (final br in branches)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(br.name, style: theme.textTheme.bodySmall),
              ),
            const SizedBox(height: 10),
            Text('CLANS',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: ink.ash, letterSpacing: 1)),
            const SizedBox(height: 4),
            Wrap(spacing: 4, runSpacing: 4, children: [
              for (final f in clans) ClanDisc(f, size: 26),
            ]),
          ]),
        );
      }

      return Stack(children: [
        const Positioned.fill(child: PickerBody(step: 1, raceId: 'dwarf')),
        Positioned.fill(child: Container(color: const Color(0x88000000))),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border.all(color: ink.seam),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: ink.seam, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                column(a),
                Container(width: 1, height: 300, color: ink.seam),
                const SizedBox(width: 10),
                column(b),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () {},
                        child:
                            Text('Pick the ${_nameOf(choices, folder, a)}'))),
                const SizedBox(width: 10),
                Expanded(
                    child: OutlinedButton(
                        onPressed: () {},
                        child:
                            Text('Pick the ${_nameOf(choices, folder, b)}'))),
              ]),
            ]),
          ),
        ),
      ]);
    });
  }
}

String _nameOf(Choices c, String folder, String id) => ((folder == 'races'
            ? c.raceOf(id)
            : c.professionOf(
                id))[folder == 'races' ? 'raceName' : 'professionName'] ??
        id)
    .toString();

/// A column of notes beside the phones.
class NotesPanel extends StatelessWidget {
  const NotesPanel({super.key, required this.title, required this.sections});
  final String title;
  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFFEDE6DC);
    const ash = Color(0xFFA9A2B3);
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'IMFellEnglishSC', fontSize: 22, color: text)),
          const SizedBox(height: 12),
          for (final (head, body) in sections) ...[
            Text(head.toUpperCase(),
                style: const TextStyle(
                    fontFamily: 'PixelifySans',
                    fontSize: 11,
                    letterSpacing: 1.1,
                    color: Color(0xFFE2B890))),
            const SizedBox(height: 3),
            Text(body,
                style: const TextStyle(
                    fontFamily: 'Spectral',
                    fontSize: 13.5,
                    height: 1.3,
                    color: ash)),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
