// The pieces of the race and profession choice (v1.599,
// docs/proposals/race-profession-choice.md): a card for each people and each
// calling (how it plays in one line, its tag, the strongest bonuses, the
// clans behind it), the open card that says who will court you and what it
// unlocks, the two steps, Compare, and the summary of who you will play as.
// The screen (lib/screens/race_profession_screen.dart) keeps the choosing and
// the creation; this file only draws.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/dice_faces.dart' show skillDisplayName;
import '../data/character_start.dart' show presetBonuses;
import '../data/clan_affinity.dart';
import '../data/factions.dart';
import '../data/skill_tree.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/game_db_providers.dart';
import '../screens/race_profession_screen.dart' show PresetMark, leadAndRest;
import '../theme/stitched_ink.dart';
import 'pixel_banner.dart';

/// The races, the professions, the skill trees and the clans, together: what
/// the choice reads.
class ChoiceBook {
  ChoiceBook({
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

  static const folderRaces = 'races';
  static const folderProfessions = 'professions';

  Map<String, dynamic> recordOf(String folder, String id) =>
      (folder == folderRaces ? races[id] : professions[id])
          as Map<String, dynamic>? ??
      const {};

  String nameOfChoice(String folder, String id) => (recordOf(folder, id)[
              folder == folderRaces ? 'raceName' : 'professionName'] ??
          id)
      .toString();

  /// The clans behind a people or a calling.
  List<Faction> clansOf(String folder, String id) => [
        for (final c in folder == folderRaces
            ? matrix.clansOfRace(id)
            : matrix.clansOfProfession(id))
          if (data.faction(c) case final f?) f,
      ];

  /// The branches the choice opens: a people's heritage, a calling's own.
  List<SkillBranch> branchesOf(String folder, String id) => [
        for (final e in trees.entries)
          if (e.value is Map<String, dynamic> &&
              (e.value[folder == folderRaces ? 'raceId' : 'professionId']
                          ?.toString() ??
                      '') ==
                  id)
            SkillBranch.fromRecord(e.key, e.value as Map<String, dynamic>),
      ]..sort((a, b) => a.order.compareTo(b.order));

  /// The clan that sponsors [branch], if one does.
  Faction? sponsorOf(SkillBranch branch) {
    for (final f in data.clans) {
      if (f.sponsors.contains(branch.id)) return f;
    }
    return null;
  }

  /// The clans that will come first to [raceId] [professionId]: those behind
  /// both, then those behind more of the calling's branches.
  List<Faction> firstCourtiers(String raceId, String professionId) {
    final byRace = matrix.clansOfRace(raceId).toSet();
    final ids = {...byRace, ...matrix.clansOfProfession(professionId)};
    int score(String c) =>
        (byRace.contains(c) ? 1 : 0) + matrix.professionLevel(c, professionId);
    final sorted = ids.toList()
      ..sort((a, b) {
        final s = score(b).compareTo(score(a));
        return s != 0 ? s : a.compareTo(b);
      });
    return [
      for (final c in sorted)
        if (data.faction(c) case final f?) f,
    ];
  }

  /// How many clans back both choices.
  int backBoth(String raceId, String professionId) => [
        for (final c in matrix.clansOfRace(raceId))
          if (matrix.professionLevel(c, professionId) > 0) c
      ].length;
}

/// The choice's book, or null while the tables load.
final choiceBookProvider = Provider<ChoiceBook?>((ref) {
  final races = ref.watch(localizedDbProvider(racesSchema)).value;
  final professions = ref.watch(localizedDbProvider(professionsSchema)).value;
  final trees = ref.watch(localizedDbProvider(skillTreesSchema)).value;
  if (races == null || professions == null || trees == null) return null;
  return ChoiceBook(
    races: races,
    professions: professions,
    trees: trees,
    data: ref.watch(clanDataProvider),
  );
});

/// A clan as a small disc: its banner on its colour.
class ClanDisc extends StatelessWidget {
  const ClanDisc(this.faction, {super.key, this.size = 30, this.name = false});

  final Faction faction;
  final double size;

  /// Its short name beside it.
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
    return Consumer(builder: (context, ref, _) {
      final lang = ref.watch(appLanguageProvider);
      return Row(mainAxisSize: MainAxisSize.min, children: [
        disc,
        const SizedBox(width: 6),
        Text(faction.shortFor(lang),
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: colour, fontWeight: FontWeight.w600)),
      ]);
    });
  }
}

/// The strongest bonuses of [record] as chips: green gives, red takes.
class StatChips extends ConsumerWidget {
  const StatChips({super.key, required this.record, this.max = 4});

  final Map<String, dynamic> record;
  final int max;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = presetBonuses(record)
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    return Wrap(spacing: 4, runSpacing: 4, children: [
      for (final e in entries.take(max))
        _chip(context, tr(ref, e.key), e.value),
    ]);
  }

  Widget _chip(BuildContext context, String label, int value) {
    final colour =
        value > 0 ? const Color(0xFF3F8F5A) : const Color(0xFFC0392B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.1),
        border: Border.all(color: colour.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('${value > 0 ? '+' : ''}$value $label',
          style:
              Theme.of(context).textTheme.labelMedium?.copyWith(color: colour)),
    );
  }
}

/// One choice as a card: its mark, name and tag, how it plays in one line,
/// the strongest bonuses and the clans behind it. [compact] is one slim line
/// (the other choices once one is open).
class ChoiceCard extends ConsumerWidget {
  const ChoiceCard({
    super.key,
    required this.book,
    required this.folder,
    required this.id,
    required this.onTap,
    this.selected = false,
    this.compact = false,
  });

  final ChoiceBook book;
  final String folder;
  final String id;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final record = book.recordOf(folder, id);
    final tag = record['tag']?.toString() ?? '';
    final clans = book.clansOf(folder, id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        key: Key('choice_card_$id'),
        color: selected
            ? ink.gold.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
              color: selected ? ink.gold : ink.seam, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(10, compact ? 7 : 10, 10, compact ? 7 : 10),
            child: Row(children: [
              PresetMark(
                  folder: folder, preset: record, size: compact ? 30 : 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(book.nameOfChoice(folder, id),
                              key: Key('choice_name_$id'),
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontFamily: InkFonts.display)),
                          if (tag.isNotEmpty)
                            InkTag(label: tag, color: ink.gold),
                        ]),
                    Text(record['playstyle']?.toString() ?? '',
                        maxLines: compact ? 1 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: ink.ash)),
                    if (!compact) ...[
                      const SizedBox(height: 6),
                      StatChips(record: record),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(spacing: -6, children: [
                    for (final f in clans.take(compact ? 3 : 4))
                      ClanDisc(f, size: compact ? 22 : 26),
                  ]),
                  if (!compact)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                          tr(ref, 'rp_clans_count')
                              .replaceAll('{n}', '${clans.length}'),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: ink.ash)),
                    ),
                ],
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.check_circle, color: ink.gold, size: 20),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// What the open choice tells: its lore, the clans that will court you (a
/// tap on a clan says what it offers), and what it unlocks.
class OpenChoice extends ConsumerStatefulWidget {
  const OpenChoice({
    super.key,
    required this.book,
    required this.folder,
    required this.id,
  });

  final ChoiceBook book;
  final String folder;
  final String id;

  @override
  ConsumerState<OpenChoice> createState() => _OpenChoiceState();
}

class _OpenChoiceState extends ConsumerState<OpenChoice> {
  bool _loreOpen = false;

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final folder = widget.folder;
    final id = widget.id;
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final record = book.recordOf(folder, id);
    final branches = book.branchesOf(folder, id);
    final names = branches.map((b) => b.name);
    final standard = record['standardSkillID']?.toString() ?? '';
    final (lead, rest) = leadAndRest(record['description']?.toString() ?? '');
    final isRace = folder == ChoiceBook.folderRaces;
    final medium = lang == AppLanguage.fr
        ? (record['powerMediumFr'] ?? record['powerMedium'])
        : record['powerMedium'];
    final scaling = switch (record['preferredScalingStat']?.toString() ?? '') {
      'strength' => 'strength_label',
      'dexterity' => 'dexterity_label',
      'constitution' => 'constitution_label',
      'intelligence' => 'intelligence_label',
      _ => null,
    };
    final lines = <(IconData, String)>[
      if (isRace) ...[
        (
          Icons.account_tree_outlined,
          tr(ref, 'rp_heritage_branch').replaceAll('{names}', names.join(', '))
        ),
        if ('${medium ?? ''}'.isNotEmpty)
          (
            Icons.brush_outlined,
            tr(ref, 'rp_power_medium').replaceAll('{name}', '$medium')
          ),
      ] else ...[
        (
          Icons.account_tree_outlined,
          tr(ref, 'rp_three_branches').replaceAll('{names}', names.join(' · '))
        ),
        if (scaling != null)
          (
            Icons.trending_up,
            tr(ref, 'rp_scales_with')
                .replaceAll('{stat}', tr(ref, scaling).toLowerCase())
          ),
        if (((record['startingSpellIds'] as List?) ?? const []).isNotEmpty)
          (Icons.auto_awesome, tr(ref, 'rp_casts')),
      ],
      if (standard.isNotEmpty)
        (
          Icons.bolt,
          tr(ref, 'rp_starting_skill')
              .replaceAll('{skill}', skillDisplayName(standard, language: lang))
        ),
    ];
    // The clans, each with why: a people's clans sponsor its heritage, a
    // calling's clans each offer one of its branches.
    final rows = <(Faction, String)>[];
    if (isRace) {
      for (final f in book.clansOf(folder, id)) {
        rows.add((
          f,
          tr(ref, 'rp_sponsors_heritage')
              .replaceAll('{names}', names.join(', '))
        ));
      }
    } else {
      for (final b in branches) {
        final f = book.sponsorOf(b);
        if (f != null) {
          rows.add(
              (f, tr(ref, 'rp_offers_branch').replaceAll('{branch}', b.name)));
        }
      }
    }
    return Container(
      key: Key('open_choice_$id'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ink.seam),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lead.isNotEmpty) ...[
            Text.rich(
              TextSpan(children: [
                TextSpan(text: lead),
                if (_loreOpen && rest.isNotEmpty) TextSpan(text: ' $rest'),
              ]),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontStyle: FontStyle.italic, height: 1.4),
            ),
            if (rest.isNotEmpty)
              InkWell(
                key: const Key('open_choice_lore'),
                onTap: () => setState(() => _loreOpen = !_loreOpen),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                      '${tr(ref, _loreOpen ? 'lore_less' : 'lore_more')} ${_loreOpen ? '▴' : '▾'}',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.colorScheme.primary)),
                ),
              ),
            const SizedBox(height: 8),
          ],
          Text(tr(ref, 'rp_clans_court').toUpperCase(),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: ink.ash, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          for (final (f, line) in rows)
            InkWell(
              key: Key('clan_row_${f.id}'),
              borderRadius: BorderRadius.circular(8),
              onTap: () =>
                  showClanSheet(context, ref, book, f, folder: folder, id: id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  ClanDisc(f, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.nameFor(lang),
                            style: theme.textTheme.titleSmall
                                ?.copyWith(color: Color(f.color))),
                        Text(line,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: ink.ash)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: ink.ash),
                ]),
              ),
            ),
          const Divider(height: 18),
          Text(tr(ref, 'rp_unlocks').toUpperCase(),
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

/// What a clan offers a choice: its words, and the branches it sponsors for
/// that people or calling.
Future<void> showClanSheet(
  BuildContext context,
  WidgetRef ref,
  ChoiceBook book,
  Faction clan, {
  required String folder,
  required String id,
}) {
  final lang = ref.read(appLanguageProvider);
  final branches = [
    for (final b in book.branchesOf(folder, id))
      if (clan.sponsors.contains(b.id)) b.name,
  ];
  final colour = Color(clan.color);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheet) {
      final theme = Theme.of(sheet);
      final ink = InkColors.of(sheet);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                ClanDisc(clan, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(clan.nameFor(lang),
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: InkFonts.display, color: colour)),
                ),
              ]),
              if (clan.mottoFor(lang).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('“${clan.mottoFor(lang)}”',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic)),
              ],
              if (clan.standsForIn(lang).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(clan.standsForIn(lang), style: theme.textTheme.bodyMedium),
              ],
              if (branches.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(tr(ref, 'rp_clan_offers').toUpperCase(),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: ink.ash, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(branches.join(' · '), style: theme.textTheme.titleSmall),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// The two steps as a switch, each with what is picked.
class StepSwitch extends ConsumerWidget {
  const StepSwitch({
    super.key,
    required this.book,
    required this.raceId,
    required this.professionId,
    required this.step,
    required this.onStep,
  });

  final ChoiceBook book;
  final String? raceId;
  final String? professionId;
  final int step;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    Widget seg(int i, String key, String? id, String folder, String slug) {
      final on = step == i;
      final record = id == null ? null : book.recordOf(folder, id);
      return Expanded(
        child: Material(
          key: Key('rp_step_$slug'),
          color: on ? ink.gold.withValues(alpha: 0.14) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side:
                BorderSide(color: on ? ink.gold : ink.seam, width: on ? 2 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onStep(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      Text(tr(ref, key).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: ink.ash, letterSpacing: 1)),
                      Text(
                          id == null
                              ? tr(ref, 'rp_choose')
                              : book.nameOfChoice(folder, id),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: id == null ? ink.ash : null)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      seg(0, 'rp_step_people', raceId, ChoiceBook.folderRaces, 'people'),
      const SizedBox(width: 8),
      seg(1, 'rp_step_calling', professionId, ChoiceBook.folderProfessions,
          'calling'),
    ]);
  }
}

/// After both picks: who you will play as, how it plays, and the clans that
/// will come first.
class SummaryCard extends ConsumerWidget {
  const SummaryCard({
    super.key,
    required this.book,
    required this.raceId,
    required this.professionId,
  });

  final ChoiceBook book;
  final String raceId;
  final String professionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final race = book.recordOf(ChoiceBook.folderRaces, raceId);
    final profession =
        book.recordOf(ChoiceBook.folderProfessions, professionId);
    final first = book.firstCourtiers(raceId, professionId).take(3);
    final both = book.backBoth(raceId, professionId);
    return Container(
      key: const Key('rp_summary'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: ink.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ink.gold, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(ref, 'rp_you_will_play').toUpperCase(),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: ink.gold, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Row(children: [
            PresetMark(folder: ChoiceBook.folderRaces, preset: race, size: 32),
            PresetMark(
                folder: ChoiceBook.folderProfessions,
                preset: profession,
                size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  '${race['raceName'] ?? ''} ${profession['professionName'] ?? ''}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontFamily: InkFonts.display)),
            ),
          ]),
          Text(profession['playstyle']?.toString() ?? '',
              style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
          const SizedBox(height: 8),
          Text(
              [
                tr(ref, 'rp_first_clans').toUpperCase(),
                if (both > 0)
                  tr(ref, 'rp_back_both')
                      .replaceAll('{n}', '$both')
                      .toUpperCase(),
              ].join(' · '),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: ink.ash, letterSpacing: 1)),
          const SizedBox(height: 6),
          Wrap(spacing: 10, runSpacing: 6, children: [
            for (final f in first) ClanDisc(f, size: 28, name: true),
          ]),
        ],
      ),
    );
  }
}

/// Two choices of one step side by side: how they play, their bonuses, their
/// branches and clans; each with a button that picks it.
Future<void> showCompareSheet(
  BuildContext context,
  WidgetRef ref,
  ChoiceBook book, {
  required String folder,
  required String first,
  required ValueChanged<String> onPick,
}) {
  final ids =
      ((folder == ChoiceBook.folderRaces ? book.races : book.professions)
              .keys
              .toList()
            ..sort())
          .cast<String>();
  var second = ids.firstWhere((i) => i != first);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheet) => StatefulBuilder(builder: (sheet, setState) {
      final theme = Theme.of(sheet);
      final ink = InkColors.of(sheet);
      Widget column(String id) {
        final record = book.recordOf(folder, id);
        final branches = book.branchesOf(folder, id);
        final clans = book.clansOf(folder, id);
        return Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: PresetMark(folder: folder, preset: record, size: 44)),
            const SizedBox(height: 4),
            Center(
              child: Text(book.nameOfChoice(folder, id),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontFamily: InkFonts.display)),
            ),
            if ((record['tag']?.toString() ?? '').isNotEmpty)
              Center(
                  child:
                      InkTag(label: record['tag'].toString(), color: ink.gold)),
            const SizedBox(height: 8),
            Text(record['playstyle']?.toString() ?? '',
                style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
            const SizedBox(height: 8),
            StatChips(record: record, max: 6),
            const SizedBox(height: 10),
            Text(tr(ref, 'rp_branches_title').toUpperCase(),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: ink.ash, letterSpacing: 1)),
            for (final b in branches)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(b.name, style: theme.textTheme.bodySmall),
              ),
            const SizedBox(height: 10),
            Text(tr(ref, 'rp_clans_title').toUpperCase(),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: ink.ash, letterSpacing: 1)),
            const SizedBox(height: 4),
            Wrap(spacing: 4, runSpacing: 4, children: [
              for (final f in clans) ClanDisc(f, size: 26),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: Key('compare_pick_$id'),
                onPressed: () {
                  onPick(id);
                  Navigator.of(sheet).pop();
                },
                child: Text(
                    tr(ref, 'rp_pick_the')
                        .replaceAll('{name}', book.nameOfChoice(folder, id)),
                    textAlign: TextAlign.center),
              ),
            ),
          ]),
        );
      }

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(spacing: 6, runSpacing: 4, children: [
                Text('${tr(ref, 'rp_compare_with')}:',
                    style: theme.textTheme.labelMedium),
                for (final id in ids)
                  if (id != first)
                    ChoiceChip(
                      key: Key('compare_with_$id'),
                      label: Text(book.nameOfChoice(folder, id),
                          style: TextStyle(color: theme.colorScheme.onSurface)),
                      selected: second == id,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => second = id),
                    ),
              ]),
            ),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              column(first),
              Container(width: 1, height: 360, color: ink.seam),
              const SizedBox(width: 10),
              column(second),
            ]),
          ]),
        ),
      );
    }),
  );
}
