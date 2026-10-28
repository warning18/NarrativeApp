// The drawing of the companion mock (ux_companion_mock_test.dart): two
// proposed versions of the camp's Party tab, built from the real companions,
// races, professions and the session's approval, health and seats. Mock
// only; nothing here ships.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/dice_faces.dart'
    show dieDisplayName, skillDisplayName;
import 'package:narrative_data_app/data/approval.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/models/ally_state.dart'
    show deriveAllyBaseStats;
import 'package:narrative_data_app/providers/game_config_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/race_profession_screen.dart'
    show PresetMark;
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';
import 'package:narrative_data_app/widgets/inventory_parts.dart'
    show InventoryDieTile;

/// One recruited companion as the Party tab needs her.
class AllyInfo {
  AllyInfo({
    required this.id,
    required this.name,
    required this.race,
    required this.profession,
    required this.professionRecord,
    required this.hp,
    required this.maxHp,
    required this.approval,
    required this.active,
    required this.dieId,
    required this.skills,
    required this.points,
    required this.likes,
    required this.dislikes,
    required this.record,
  });

  final String id;
  final String name;
  final String race;
  final String profession;
  final Map<String, dynamic> professionRecord;
  final int hp;
  final int maxHp;
  final int approval;
  final bool active;
  final String dieId;
  final List<String> skills;
  final int points;
  final List<String> likes;
  final List<String> dislikes;
  final Map<String, dynamic> record;

  ApprovalTier get tier => approvalTierFor(approval);
}

Color tierColor(BuildContext context, ApprovalTier tier) {
  final scheme = Theme.of(context).colorScheme;
  return switch (tier) {
    ApprovalTier.devoted => const Color(0xFFD9A400),
    ApprovalTier.friendly => const Color(0xFF3F8F5A),
    ApprovalTier.neutral => InkColors.of(context).ash,
    _ => scheme.error,
  };
}

const Map<ApprovalTier, String> tierName = {
  ApprovalTier.devoted: 'Devoted',
  ApprovalTier.friendly: 'Friendly',
  ApprovalTier.neutral: 'Neutral',
  ApprovalTier.wary: 'Wary',
  ApprovalTier.estranged: 'Estranged',
};

/// The recruited companions of the session, seated first.
class WithAllies extends ConsumerWidget {
  const WithAllies(this.builder, {super.key});
  final Widget Function(BuildContext, WidgetRef, List<AllyInfo> allies,
      List<Map<String, dynamic>> unmet, Map<String, dynamic> quests) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final companions = ref.watch(localizedDbProvider(companionsSchema)).value;
    final races = ref.watch(localizedDbProvider(racesSchema)).value;
    final professions = ref.watch(localizedDbProvider(professionsSchema)).value;
    final config = ref.watch(gameConfigProvider).value;
    final quests =
        ref.watch(localizedDbProvider(questsSchema)).value ?? const {};
    if (companions == null ||
        races == null ||
        professions == null ||
        config == null) {
      return const SizedBox.shrink();
    }
    String deeds(Map<String, dynamic> c, bool liked) => [
          for (final (field, label) in const [
            ('approvesGood', 'kindness'),
            ('approvesEvil', 'cruelty'),
            ('approvesProfit', 'profit'),
          ])
            if (((c[field] as num?)?.toInt() ?? 0) * (liked ? 1 : -1) > 0)
              label,
        ].join(', ');
    final out = <AllyInfo>[];
    for (final ally in session.recruitedAllies) {
      final c = companions[ally.companionId] as Map<String, dynamic>? ?? {};
      final race = races[c['raceId']] as Map<String, dynamic>? ?? const {};
      final prof =
          professions[c['professionId']] as Map<String, dynamic>? ?? const {};
      final base =
          deriveAllyBaseStats(gameConfig: config, race: race, profession: prof);
      final maxHp = scaledMaxHealth(base.maxHealth, session.level);
      out.add(AllyInfo(
        id: ally.companionId,
        name: (c['companionName'] ?? ally.companionId).toString(),
        race: (race['raceName'] ?? '').toString(),
        profession: (prof['professionName'] ?? '').toString(),
        professionRecord: prof,
        hp: ally.currentHealth.clamp(0, maxHp),
        maxHp: maxHp,
        approval: ally.approval,
        active: session.activeAllyIds.contains(ally.companionId),
        dieId: (c['signatureDiceId'] ?? '').toString(),
        skills: ally.unlockedSkillIds,
        points: ally.skillPoints,
        likes: [
          for (final s in deeds(c, true).split(', '))
            if (s.isNotEmpty) s
        ],
        dislikes: [
          for (final s in deeds(c, false).split(', '))
            if (s.isNotEmpty) s
        ],
        record: c,
      ));
    }
    // Seated first, then the bench in the order recruited.
    out.sort((a, b) => (a.active ? 0 : 1).compareTo(b.active ? 0 : 1));
    final have = {for (final a in out) a.id};
    final unmet = [
      for (final e in companions.entries)
        if (!have.contains(e.key) && e.value is Map<String, dynamic>)
          e.value as Map<String, dynamic>
    ];
    return builder(context, ref, out, unmet, quests);
  }
}

/// A phone with the camp's tab strip over [child].
class Phone extends StatelessWidget {
  const Phone({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.chrome = true,
  });
  final double width;
  final double height;
  final bool chrome;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    Widget tab(String label, IconData icon, {bool on = false}) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: on ? ink.gold : ink.seam, width: on ? 2 : 1)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 16, color: on ? ink.gold : ink.ash),
              const SizedBox(width: 4),
              Text(label,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: on ? null : ink.ash)),
            ]),
          ),
        );
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
        child: chrome
            ? Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(children: [
                    Icon(Icons.local_fire_department,
                        size: 22, color: ink.ember),
                    const SizedBox(width: 8),
                    Text('Camp',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontFamily: InkFonts.display)),
                  ]),
                ),
                Row(children: [
                  tab('Road', Icons.route_outlined),
                  tab('Town', Icons.holiday_village_outlined),
                  tab('Party', Icons.groups_outlined, on: true),
                  tab('Sea', Icons.anchor),
                ]),
                Expanded(child: ClipRect(child: child)),
              ])
            : child,
      ),
    );
  }
}

/// A companion's face: the class mark on a disc ringed in the tier's colour.
class Portrait extends StatelessWidget {
  const Portrait(this.info, {super.key, this.size = 44, this.dim = false});
  final AllyInfo info;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final ring = tierColor(context, info.tier);
    return Opacity(
      opacity: dim ? 0.55 : 1,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: ring, width: 2.4),
        ),
        child: PresetMark(
            folder: 'professions',
            preset: info.professionRecord,
            size: size * 0.62),
      ),
    );
  }
}

/// A slim bar: [value] of 1.
class HpBar extends StatelessWidget {
  const HpBar(
      {super.key, required this.hp, required this.max, this.height = 5});
  final int hp;
  final int max;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final f = max <= 0 ? 0.0 : (hp / max).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: f,
        minHeight: height,
        color: f < 0.5 ? ink.blood : const Color(0xFF3F8F5A),
        backgroundColor: ink.seam,
      ),
    );
  }
}

/// The tier as a small chip.
Widget tierChip(BuildContext context, AllyInfo a) {
  final colour = tierColor(context, a.tier);
  return FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: _tierChipBody(context, a, colour),
  );
}

Widget _tierChipBody(BuildContext context, AllyInfo a, Color colour) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: colour.withValues(alpha: 0.12),
      border: Border.all(color: colour.withValues(alpha: 0.7)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (a.tier == ApprovalTier.devoted)
        Icon(Icons.favorite, size: 11, color: colour),
      if (a.tier == ApprovalTier.devoted) const SizedBox(width: 3),
      Text(tierName[a.tier]!,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: colour, fontWeight: FontWeight.w700)),
    ]),
  );
}

Widget seatButton(BuildContext context, String label,
    {bool filled = true, bool enabled = true}) {
  final ink = InkColors.of(context);
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: filled && enabled ? ink.gold : null,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: enabled ? ink.gold : ink.seam),
    ),
    child: Text(label,
        style: theme.textTheme.labelMedium?.copyWith(
            color: filled && enabled
                ? Colors.white
                : enabled
                    ? ink.gold
                    : ink.ash)),
  );
}

Widget sectionTitle(BuildContext context, String text, {String? trailing}) =>
    Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
      child: Row(children: [
        Expanded(
          child: Text(text.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: InkColors.of(context).ash, letterSpacing: 1.2)),
        ),
        if (trailing != null)
          Text(trailing,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: InkColors.of(context).ash)),
      ]),
    );

// ---------------------------------------------------------------------------
// A: the same list, less on it, and a seat strip.
// ---------------------------------------------------------------------------

/// The seats: the party as it will fight, the third seat shown locked.
class SeatStrip extends StatelessWidget {
  const SeatStrip({super.key, required this.allies, this.capacity = 2});
  final List<AllyInfo> allies;
  final int capacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final seated = allies.where((a) => a.active).toList();
    Widget seat(int i) {
      if (i < seated.length) {
        final a = seated[i];
        return Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            decoration: BoxDecoration(
              color: ink.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ink.gold),
            ),
            child: Column(children: [
              Portrait(a, size: 42),
              const SizedBox(height: 4),
              Text(a.name.split(' ').last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              HpBar(hp: a.hp, max: a.maxHp),
            ]),
          ),
        );
      }
      final locked = i >= capacity;
      return Expanded(
        child: Container(
          height: 105,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ink.seam),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(locked ? Icons.lock_outline : Icons.add, color: ink.ash),
            const SizedBox(height: 4),
            Text(locked ? 'Barracks Annex' : 'Empty seat',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          seat(i),
        ],
      ]),
    );
  }
}

/// A companion in A: one compact row, everything she is at a glance.
class ARow extends StatelessWidget {
  const ARow({super.key, required this.info, this.seatFull = false});
  final AllyInfo info;
  final bool seatFull;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final a = info;
    final skills = a.skills.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: a.active
            ? ink.gold.withValues(alpha: 0.06)
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: a.active ? ink.gold : ink.seam),
      ),
      child: Column(children: [
        Row(children: [
          Portrait(a, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(a.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontFamily: InkFonts.display)),
                  ),
                  const SizedBox(width: 6),
                  tierChip(context, a),
                ]),
                Text('${a.race} ${a.profession}',
                    style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: HpBar(hp: a.hp, max: a.maxHp)),
                  const SizedBox(width: 6),
                  Text('${a.hp}/${a.maxHp}',
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (a.active)
            seatButton(context, 'Seated', filled: false)
          else
            seatButton(context, seatFull ? 'Swap in' : 'Take a seat'),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          InventoryDieTile(dieId: a.dieId, faces: 6, size: 22),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
                '${dieDisplayName(a.dieId)} · $skills ${skills == 1 ? 'skill' : 'skills'}'
                '${a.points > 0 ? ' · ${a.points} to learn' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
          ),
          for (final (icon, dot) in [
            (Icons.backpack_outlined, false),
            (Icons.auto_awesome_outlined, a.points > 0),
            (Icons.casino_outlined, false),
          ])
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 34,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ink.seam),
                  ),
                  child: Icon(icon, size: 17, color: ink.gold),
                ),
                if (dot)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                            color: ink.gold, shape: BoxShape.circle)),
                  ),
              ]),
            ),
        ]),
      ]),
    );
  }
}

class APage extends StatelessWidget {
  const APage({super.key});

  @override
  Widget build(BuildContext context) {
    return WithAllies((context, ref, allies, unmet, quests) {
      final seated = allies.where((a) => a.active).toList();
      final bench = allies.where((a) => !a.active).toList();
      final full = seated.length >= 2;
      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
        children: [
          SeatStrip(allies: allies),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle(context, 'In your party',
                      trailing: '${seated.length} / 2'),
                  for (final a in seated) ARow(info: a),
                  sectionTitle(context, 'On the bench',
                      trailing: 'they miss your choices'),
                  for (final a in bench) ARow(info: a, seatFull: full),
                ]),
          ),
        ],
      );
    });
  }
}

/// What a tap on "Swap in" opens when the seats are full: who steps out.
class SwapSheet extends StatelessWidget {
  const SwapSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return WithAllies((context, ref, allies, unmet, quests) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      final seated = allies.where((a) => a.active).toList();
      final incoming = allies.firstWhere((a) => !a.active);
      return Stack(children: [
        const Positioned.fill(child: APage()),
        Positioned.fill(child: Container(color: const Color(0x88000000))),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
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
              const SizedBox(height: 12),
              Row(children: [
                Portrait(incoming, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${incoming.name} takes a seat. Who steps out?',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontFamily: InkFonts.display)),
                ),
              ]),
              const SizedBox(height: 10),
              for (final a in seated)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ink.seam),
                  ),
                  child: Row(children: [
                    Portrait(a, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name, style: theme.textTheme.titleSmall),
                          Text('${a.hp}/${a.maxHp} HP · ${tierName[a.tier]}',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: ink.ash)),
                        ],
                      ),
                    ),
                    seatButton(context, 'Step out', filled: false),
                  ]),
                ),
            ]),
          ),
        ),
      ]);
    });
  }
}

// ---------------------------------------------------------------------------
// B: the party as a formation, a page for each companion, and who is not yet
// (or no longer) with you.
// ---------------------------------------------------------------------------

class BPage extends StatelessWidget {
  const BPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WithAllies((context, ref, allies, unmet, quests) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      final seated = allies.where((a) => a.active).toList();
      final bench = allies.where((a) => !a.active).toList();
      Widget bigSeat(AllyInfo a) => Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
              decoration: BoxDecoration(
                color: ink.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ink.gold, width: 1.6),
              ),
              child: Column(children: [
                Portrait(a, size: 52),
                const SizedBox(height: 4),
                Text(a.name.split(' ').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                HpBar(hp: a.hp, max: a.maxHp),
                const SizedBox(height: 4),
                tierChip(context, a),
              ]),
            ),
          );
      Widget benchCard(AllyInfo a) => Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ink.seam),
            ),
            child: Row(children: [
              Portrait(a, size: 38),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name.split(' ').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall),
                    tierChip(context, a),
                  ],
                ),
              ),
            ]),
          );
      Widget ghost(String name, String line, {bool lost = false}) => Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ink.seam),
            ),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ink.seam, width: 2)),
                child: Icon(lost ? Icons.logout : Icons.help_outline,
                    size: 20, color: ink.ash),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: ink.ash)),
                    Text(line,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash)),
                  ],
                ),
              ),
            ]),
          );
      String questOf(Map<String, dynamic> c) {
        final q = quests[c['recruitQuestId']] as Map<String, dynamic>?;
        return (q?['questName'] ?? '').toString();
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        children: [
          sectionTitle(context, 'Your party',
              trailing: '${seated.length} / 2 seats'),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final a in seated) ...[bigSeat(a), const SizedBox(width: 8)],
            Expanded(
              child: Container(
                height: 150,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ink.seam),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: ink.ash),
                      const SizedBox(height: 4),
                      Text('Third seat',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: ink.ash)),
                      Text('Barracks Annex',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: ink.ash)),
                    ]),
              ),
            ),
          ]),
          sectionTitle(context, 'On the bench', trailing: 'tap to see them'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final a in bench)
              FractionallySizedBox(
                widthFactor: 1,
                child: LayoutBuilder(builder: (context, c) {
                  return SizedBox(
                      width: (c.maxWidth - 8) / 2, child: benchCard(a));
                }),
              ),
          ]),
          sectionTitle(context, 'Not with you'),
          Column(children: [
            for (final c in unmet.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ghost('???', 'Find them: ${questOf(c)}'),
              ),
            ghost('Malrik Sarn', 'Left when your choices turned him away',
                lost: true),
          ]),
        ],
      );
    });
  }
}

/// Approval as a meter with its thresholds named.
class ApprovalMeter extends StatelessWidget {
  const ApprovalMeter({super.key, required this.approval});
  final int approval;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    double at(int v) => (v - minApproval) / (maxApproval - minApproval);
    final colour = tierColor(context, approvalTierFor(approval));
    Widget mark(int v, String label) => Align(
          alignment: Alignment(at(v) * 2 - 1, 0),
          child: Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: ink.ash, fontSize: 10)),
        );
    return Column(children: [
      LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        return SizedBox(
          height: 18,
          child: Stack(alignment: Alignment.centerLeft, children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                  color: ink.seam, borderRadius: BorderRadius.circular(3)),
            ),
            Container(
              width: w * at(approval),
              height: 6,
              decoration: BoxDecoration(
                  color: colour, borderRadius: BorderRadius.circular(3)),
            ),
            for (final v in [
              leavingApproval,
              waryApproval,
              friendlyApproval,
              devotedApproval
            ])
              Positioned(
                left: w * at(v) - 1,
                child: Container(width: 2, height: 14, color: ink.ash),
              ),
            Positioned(
              left: w * at(approval) - 7,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colour,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ]),
        );
      }),
      SizedBox(
        height: 16,
        child: Stack(children: [
          mark(leavingApproval, 'leaves'),
          mark(waryApproval, 'wary'),
          mark(friendlyApproval, 'friendly'),
          mark(devotedApproval, 'devoted'),
        ]),
      ),
    ]);
  }
}

/// A companion's own page: seat, approval and what moves it, die, skills.
class CompanionPage extends StatelessWidget {
  const CompanionPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return WithAllies((context, ref, allies, unmet, quests) {
      final theme = Theme.of(context);
      final ink = InkColors.of(context);
      final a = allies.firstWhere((x) => x.id == id);
      final colour = tierColor(context, a.tier);
      final effect = switch (a.tier) {
        ApprovalTier.devoted => '+10% damage and health in fights',
        ApprovalTier.friendly => '+5% damage in fights',
        ApprovalTier.neutral => 'No bonus yet',
        _ => '−10% damage; leaves at −12',
      };
      Widget chips(List<String> items, Color c, IconData icon) => Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in items)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    border: Border.all(color: c.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 13, color: c),
                    const SizedBox(width: 4),
                    Text(s,
                        style: theme.textTheme.labelMedium?.copyWith(color: c)),
                  ]),
                ),
            ],
          );
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        children: [
          Row(children: [
            Portrait(a, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontFamily: InkFonts.display)),
                  Text('${a.race} ${a.profession}',
                      style:
                          theme.textTheme.bodyMedium?.copyWith(color: ink.ash)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: HpBar(hp: a.hp, max: a.maxHp, height: 7)),
                    const SizedBox(width: 6),
                    Text('${a.hp}/${a.maxHp}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash)),
                  ]),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: seatButton(context,
                  a.active ? 'Seated: move to the bench' : 'Take a seat',
                  filled: !a.active),
            ),
          ]),
          sectionTitle(context, 'How they feel about you'),
          Row(children: [
            tierChip(context, a),
            const SizedBox(width: 8),
            Expanded(
              child: Text(effect,
                  style: theme.textTheme.bodySmall?.copyWith(color: colour)),
            ),
          ]),
          const SizedBox(height: 6),
          ApprovalMeter(approval: a.approval),
          const SizedBox(height: 6),
          Text(
              'Your choices move it while they are in the party. Benched, they do not see them.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: chips(
                    a.likes, const Color(0xFF3F8F5A), Icons.thumb_up_outlined)),
            const SizedBox(width: 8),
            Expanded(
                child: chips(a.dislikes, const Color(0xFFC0392B),
                    Icons.thumb_down_outlined)),
          ]),
          sectionTitle(context, 'Their die'),
          _tapRow(
            context,
            leading: InventoryDieTile(dieId: a.dieId, faces: 6, size: 40),
            title: dieDisplayName(a.dieId),
            line: 'd6 · ${dieSkinOf(a.dieId).material}',
          ),
          sectionTitle(context, 'Skills',
              trailing: a.points > 0 ? '${a.points} to learn' : null),
          Wrap(spacing: 8, children: [
            for (final s in a.skills.take(5))
              Chip(
                label: Text(skillDisplayName(s),
                    style: theme.textTheme.labelMedium),
                visualDensity: VisualDensity.compact,
              ),
            if (a.skills.isEmpty)
              Text('Starter skills only.',
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
          ]),
          sectionTitle(context, 'Gear'),
          _tapRow(context,
              leading: Icon(Icons.backpack_outlined, color: ink.gold),
              title: 'Five slots',
              line: 'Open their inventory'),
        ],
      );
    });
  }

  Widget _tapRow(BuildContext context,
      {required Widget leading, required String title, required String line}) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ink.seam),
      ),
      child: Row(children: [
        SizedBox(width: 44, child: Center(child: leading)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              Text(line,
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: ink.ash),
      ]),
    );
  }
}

/// The guide dog's page, as it would stand once earned: the sprite from the
/// tutorial, a placeholder die and skills (Core's to define).
class DogPage extends StatelessWidget {
  const DogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    const sprite =
        'assets/visuals/companion/dog_companion_animations/Sitting_down/rotations/south.png';
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      children: [
        Row(children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
              border: Border.all(color: const Color(0xFF3F8F5A), width: 2.4),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(sprite,
                fit: BoxFit.contain, filterQuality: FilterQuality.none),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The guide dog',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontFamily: InkFonts.display)),
                Text('Companion · earned in the second town',
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: ink.ash)),
                const SizedBox(height: 4),
                Row(children: [
                  const Expanded(child: HpBar(hp: 30, max: 30, height: 7)),
                  const SizedBox(width: 6),
                  Text('30/30',
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                ]),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 10),
        seatButton(context, 'Take a seat'),
        sectionTitle(context, 'How they feel about you'),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: ink.ash),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Neutral',
                style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('No bonus yet',
                style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
          ),
        ]),
        const SizedBox(height: 6),
        const ApprovalMeter(approval: startingApproval),
        const SizedBox(height: 6),
        Text(
            'Placeholder: likes, dislikes, die, skills and stats are Core’s to set. The dog is a companion like the others: it takes a seat, can be benched or replaced.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
        sectionTitle(context, 'Their die'),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ink.seam),
          ),
          child: Row(children: [
            const SizedBox(
                width: 44,
                child: Center(
                    child: InventoryDieTile(
                        dieId: 'twinfang_die', faces: 6, size: 40))),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('A dog’s die (placeholder)',
                      style: theme.textTheme.titleSmall),
                  Text('Bite, bark, guard',
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ink.ash),
          ]),
        ),
      ],
    );
  }
}

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
