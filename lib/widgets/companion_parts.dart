// The pieces of the Party tab's formation and of a companion's page (v1.606):
// each recruited companion as the screens need them (name, people, health,
// approval, seat, die, skills), their portrait (the class mark; the guide dog's
// own sprite for Vica, in the look her hero's alignment gives her, as in the
// tutorial), a health bar, the approval tier as a chip, and the approval meter
// with its thresholds read from approval.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/approval.dart';
import '../data/companion_sprites.dart';
import '../combat/combat_engine.dart' show scaledMaxHealth;
import '../gamedata/db_schema.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../screens/race_profession_screen.dart' show PresetMark;
import '../theme/stitched_ink.dart';
import 'moments.dart' show ApprovalHeart;

/// The id of the guide dog (companions.json).
const String _guideDogId = 'vica';

/// One recruited companion, worked out for display.
class CompanionView {
  const CompanionView({
    required this.id,
    required this.record,
    required this.ally,
    required this.name,
    required this.raceName,
    required this.professionName,
    required this.professionRecord,
    required this.hp,
    required this.maxHp,
    required this.active,
  });

  final String id;
  final Map<String, dynamic> record;
  final AllyState ally;
  final String name;
  final String raceName;
  final String professionName;
  final Map<String, dynamic> professionRecord;
  final int hp;
  final int maxHp;
  final bool active;

  int get approval => ally.approval;
  ApprovalTier get tier => approvalTierFor(ally.approval);
  String get dieId => (record['signatureDiceId'] ?? '').toString();
  bool get isGuideDog => id == _guideDogId;
}

/// The recruited companions, seated first (in the order seated), then the
/// bench in the order recruited; null while the tables load.
final companionViewsProvider = Provider<List<CompanionView>?>((ref) {
  final session = ref.watch(playerSessionProvider);
  final companions = ref.watch(localizedDbProvider(companionsSchema)).value;
  final races = ref.watch(localizedDbProvider(racesSchema)).value;
  final professions = ref.watch(localizedDbProvider(professionsSchema)).value;
  final config = ref.watch(gameConfigProvider).value;
  if (companions == null ||
      races == null ||
      professions == null ||
      config == null) {
    return null;
  }
  final views = <CompanionView>[];
  for (final ally in session.recruitedAllies) {
    final record = companions[ally.companionId] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final race = races[record['raceId']] as Map<String, dynamic>? ?? const {};
    final profession =
        professions[record['professionId']] as Map<String, dynamic>? ??
            const {};
    final base = deriveAllyBaseStats(
        gameConfig: config, race: race, profession: profession);
    final maxHp = scaledMaxHealth(base.maxHealth, session.level);
    views.add(CompanionView(
      id: ally.companionId,
      record: record,
      ally: ally,
      name: (record['companionName'] ?? ally.companionId).toString(),
      raceName: (race['raceName'] ?? '').toString(),
      professionName: (profession['professionName'] ?? '').toString(),
      professionRecord: profession,
      hp: ally.currentHealth.clamp(0, maxHp),
      maxHp: maxHp,
      active: session.activeAllyIds.contains(ally.companionId),
    ));
  }
  int seatOrder(CompanionView v) {
    final i = session.activeAllyIds.indexOf(v.id);
    return i < 0 ? 1 << 20 : i;
  }

  views.sort((a, b) => seatOrder(a).compareTo(seatOrder(b)));
  return views;
});

/// How many companions are still to be met: in the table, never recruited,
/// and not lost or gone (those are not told).
final unmetCompanionCountProvider = Provider<int>((ref) {
  final session = ref.watch(playerSessionProvider);
  final companions =
      ref.watch(localizedDbProvider(companionsSchema)).value ?? const {};
  final known = {
    for (final a in session.recruitedAllies) a.companionId,
    ...session.lostAllyIds,
    ...session.departedAllyIds,
  };
  return companions.keys.where((id) => !known.contains(id)).length;
});

/// The colour of an approval tier.
Color tierColorOf(BuildContext context, ApprovalTier tier) {
  final scheme = Theme.of(context).colorScheme;
  return switch (tier) {
    ApprovalTier.devoted => const Color(0xFFD9A400),
    ApprovalTier.friendly => const Color(0xFF3F8F5A),
    ApprovalTier.neutral => InkColors.of(context).ash,
    _ => scheme.error,
  };
}

/// The guide dog's picture for a hero of [alignment] ('Good', 'Evil', else
/// neutral): the sitting pose, as in the tutorial.
String _dogPortraitAsset(String alignment) => switch (alignment) {
      'Good' => '$companionAssetsRoot/Make_it_with_angel_w/rotations/south.png',
      'Evil' => '$companionAssetsRoot/Make_it_with_demon_w/rotations/south.png',
      _ => '$companionAssetsRoot/Sitting_down/rotations/south.png',
    };

/// A round portrait ringed in the approval tier's colour: the class mark, or
/// the guide dog's own sprite.
class CompanionPortrait extends ConsumerWidget {
  const CompanionPortrait(this.view,
      {super.key, this.size = 44, this.dim = false});
  final CompanionView view;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ring = tierColorOf(context, view.tier);
    final alignment =
        ref.watch(playerSessionProvider.select((s) => s.alignmentLabel));
    return Opacity(
      opacity: dim ? 0.55 : 1,
      child: Container(
        key: Key('companion_portrait_${view.id}'),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: ring, width: 2.4),
        ),
        child: view.isGuideDog
            ? ClipOval(
                child: Image.asset(_dogPortraitAsset(alignment),
                    width: size * 0.82,
                    height: size * 0.82,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (_, __, ___) => PresetMark(
                        folder: 'professions',
                        preset: view.professionRecord,
                        size: size * 0.62)))
            : PresetMark(
                folder: 'professions',
                preset: view.professionRecord,
                size: size * 0.62),
      ),
    );
  }
}

/// A slim health bar: [hp] of [max].
class HealthBar extends StatelessWidget {
  const HealthBar(
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

/// The approval tier as a small chip (a heart for the devoted).
class TierChip extends ConsumerWidget {
  const TierChip(this.tier, {super.key, this.textKey});
  final ApprovalTier tier;
  final Key? textKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colour = tierColorOf(context, tier);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.12),
          border: Border.all(color: colour.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (tier == ApprovalTier.devoted) ...[
            const ApprovalHeart(size: 11),
            const SizedBox(width: 3),
          ],
          Text(tr(ref, approvalTierKey(tier)),
              key: textKey,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: colour, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

/// Approval as a meter with its thresholds named (the numbers are
/// approval.dart's: leaves, wary, friendly, devoted).
class ApprovalMeter extends ConsumerWidget {
  const ApprovalMeter({super.key, required this.approval});
  final int approval;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    double at(int v) => (v - minApproval) / (maxApproval - minApproval);
    final colour = tierColorOf(context, approvalTierFor(approval));
    String tierWord(ApprovalTier t) =>
        tr(ref, approvalTierKey(t)).toLowerCase();
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
                  border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2),
                ),
              ),
            ),
          ]),
        );
      }),
      // The words under the ticks: the two close together lean apart (friendly
      // ends at its tick, devoted starts at its), so they never meet.
      LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final style =
            theme.textTheme.labelSmall?.copyWith(color: ink.ash, fontSize: 10);
        Widget word(int v, String label, {int lean = 0}) {
          final x = w * at(v);
          final text = Text(label, style: style);
          return switch (lean) {
            < 0 => Positioned(right: w - x, child: text),
            > 0 => Positioned(left: x, child: text),
            _ => Positioned(
                left: x - 40,
                width: 80,
                child: Center(child: text),
              ),
          };
        }

        return SizedBox(
          height: 16,
          child: Stack(children: [
            word(leavingApproval, tr(ref, 'companion_leaves_mark')),
            word(waryApproval, tierWord(ApprovalTier.wary)),
            word(friendlyApproval, tierWord(ApprovalTier.friendly), lean: -1),
            word(devotedApproval, tierWord(ApprovalTier.devoted), lean: 1),
          ]),
        );
      }),
    ]);
  }
}
