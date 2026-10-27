// The Town view's districts as wave 18 makes them (v1.572): a district a side
// quest keeps shut is shuttered (its lock and the reason), the others show
// who holds them, with the holder's flag, how firmly (its influence there,
// as a ring on the plan and a bar in the row) and a mark when the district
// changed hands. The rules are Core's (district_influence.dart, city_
// districts.dart); this file reads them for the screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/city_districts.dart' show districtLocked;
import '../data/clan_power.dart' show holderOf;
import '../data/district_influence.dart';
import '../gamedata/db_schema.dart' show questsSchema;
import '../providers/game_db_providers.dart' show gameDbProvider;
import '../data/factions.dart';
import '../data/geography.dart';
import '../data/town_rulers.dart' show TownRuler;
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';
import 'city_chart/city_chart.dart' show CityChartHold;
import 'pixel_banner.dart' show ClanFlag, clanBannerId;

/// What the Town view says of one district.
class DistrictStanding {
  const DistrictStanding({
    required this.id,
    this.locked = false,
    this.lockedText = '',
    this.lockQuest = '',
    this.holderId = '',
    this.holderName = '',
    this.holderColor = const Color(0xFF7C766B),
    this.holderAccent = const Color(0xFF4F4B44),
    this.influence,
    this.rivalId = '',
    this.rivalName = '',
    this.rivalColor,
    this.rivalInfluence = 0,
    this.flipped = false,
  });

  final String id;

  /// Shut by a side quest: the reason (geography.json's `lockedText`) and
  /// the quest that opens it.
  final bool locked;
  final String lockedText;
  final String lockQuest;

  /// The holding clan ('' for none) and its colours.
  final String holderId;
  final String holderName;
  final Color holderColor;
  final Color holderAccent;

  /// The holder's influence here (0..100), or null where influence is not
  /// counted (a town outside [influenceTowns]).
  final int? influence;

  /// The strongest other clan with influence here, and how much.
  final String rivalId;
  final String rivalName;
  final Color? rivalColor;
  final int rivalInfluence;

  /// Changed hands by influence (see districtFlippedFlag).
  final bool flipped;

  bool get held => holderId.isNotEmpty;

  /// The crest the plan draws, or null for a district no one holds.
  CityChartHold? get crest => !held
      ? null
      : CityChartHold(
          fill: holderColor,
          accent: holderAccent,
          hold: influence == null ? null : influence! / maxInfluence,
          rival: rivalInfluence / maxInfluence,
          rivalFill: rivalColor,
          // The rival takes the district [flipMargin] over the holder.
          flipAt: influence == null
              ? 0
              : ((influence! + flipMargin) / maxInfluence).clamp(0.0, 1.0),
          flipped: flipped,
        );
}

/// The standing of each of [districtIds] of the town [cityId] now.
Map<String, DistrictStanding> districtStandingsOf({
  required Iterable<String> districtIds,
  required String? cityId,
  required Geography geography,
  required PoliticsState politics,
  required List<String> flags,
  required List<String> completedQuestIds,
  required ClanData data,
  required Map<String, TownRuler> rulers,
  required AppLanguage language,
}) {
  final french = language == AppLanguage.fr;
  final counted = cityId != null && influenceTowns.containsKey(cityId);
  Color colour(String clan) {
    final f = data.faction(clan);
    return f == null ? const Color(0xFF7C766B) : Color(f.color | 0xFF000000);
  }

  return {
    for (final id in districtIds)
      id: () {
        final place = geography.place(id);
        final locked = districtLocked(geography, id, flags, completedQuestIds);
        final ruler = rulers[id];
        final holder = ruler != null && !ruler.isNeutral
            ? ruler.clanId
            : holderOf(id, geography, politics);
        var rivalId = '';
        var rivalInfluence = 0;
        if (counted && holder.isNotEmpty) {
          for (final e
              in (politics.influence[id] ?? const <String, int>{}).entries) {
            if (e.key != holder && e.value > rivalInfluence) {
              rivalId = e.key;
              rivalInfluence = e.value;
            }
          }
        }
        return DistrictStanding(
          id: id,
          locked: locked,
          lockedText: locked ? place?.lockedTextFor(french) ?? '' : '',
          lockQuest: locked ? place?.lockQuest ?? '' : '',
          holderId: locked ? '' : holder,
          holderName: holder.isEmpty
              ? ''
              : data.faction(holder)?.shortFor(language) ?? holder,
          holderColor: ruler == null ? colour(holder) : Color(ruler.color),
          holderAccent: ruler == null ? colour(holder) : Color(ruler.accent),
          influence: counted && holder.isNotEmpty && !locked
              ? influenceIn(politics, geography, id, holder)
              : null,
          rivalId: rivalId,
          rivalName: rivalId.isEmpty
              ? ''
              : data.faction(rivalId)?.shortFor(language) ?? rivalId,
          rivalColor: rivalId.isEmpty ? null : colour(rivalId),
          rivalInfluence: rivalInfluence,
          flipped: flags.contains(districtFlippedFlag(id)),
        );
      }(),
  };
}

/// The line under a district's name in the Town view's list: the reason it
/// is shut, or who holds it, with a bar of the holder's influence against the
/// strongest rival's (holder left, rival right) and the numbers.
class DistrictStandingLine extends ConsumerWidget {
  const DistrictStandingLine(this.standing, {super.key});

  final DistrictStanding standing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final s = standing;
    if (s.locked) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(s.lockedText,
            key: Key('district_locked_text_${s.id}'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
      );
    }
    if (!s.held) return const SizedBox.shrink();
    final influence = s.influence;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (s.flipped) ...[
            const Icon(Icons.star, size: 12, color: Color(0xFFF2C14E)),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
                [
                  influence == null
                      ? s.holderName
                      : '${s.holderName} $influence',
                  if (s.flipped) tr(ref, 'district_changed_hands'),
                ].join(' · '),
                key: Key('district_holder_${s.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
          ),
        ]),
        if (influence != null) ...[
          const SizedBox(height: 3),
          InfluenceBar(
            key: Key('district_influence_${s.id}'),
            holder: influence,
            holderColor: s.holderColor,
            rival: s.rivalInfluence,
            rivalColor: s.rivalColor,
            rivalName: s.rivalName,
          ),
        ],
      ]),
    );
  }
}

/// A two-colour bar: the holder's influence from the left, the strongest
/// rival's from the right, the rival's name and number under it (the
/// holder's are on the line above).
class InfluenceBar extends StatelessWidget {
  const InfluenceBar({
    super.key,
    required this.holder,
    required this.holderColor,
    required this.rival,
    this.rivalColor,
    this.rivalName = '',
  });

  final int holder;
  final Color holderColor;
  final int rival;
  final Color? rivalColor;
  final String rivalName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final h = holder.clamp(0, maxInfluence);
    final r = rival.clamp(0, maxInfluence - h);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          Widget part(double x, double width, Color c) => Positioned(
              left: x,
              width: width,
              top: 0,
              bottom: 0,
              child: ColoredBox(color: c));
          return SizedBox(
            height: 6,
            width: w,
            child: Stack(children: [
              Positioned.fill(child: ColoredBox(color: ink.seam)),
              part(0, w * h / maxInfluence, holderColor),
              if (r > 0)
                part(w * (maxInfluence - r) / maxInfluence,
                    w * r / maxInfluence, rivalColor ?? ink.ash),
            ]),
          );
        }),
      ),
      if (rival > 0) ...[
        const SizedBox(height: 2),
        Text('$rivalName $rival',
            style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
      ],
    ]);
  }
}

/// What leads a district's row: its holder's flag, a padlock for a shut
/// district, else the row's own marker.
class DistrictLead extends StatelessWidget {
  const DistrictLead(this.standing, {super.key, required this.plain});

  /// The row's own marker (the district's colour dot).
  final Widget plain;
  final DistrictStanding standing;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    if (standing.locked) {
      return SizedBox(
          width: 22,
          child: Center(
              child: Icon(Icons.lock_outline, size: 18, color: ink.ash)));
    }
    if (standing.held && clanBannerId(standing.holderId) != null) {
      return SizedBox(
        width: 22,
        child:
            Center(child: ClanFlag(factionId: standing.holderId, height: 26)),
      );
    }
    return SizedBox(width: 22, child: Center(child: plain));
  }
}

/// Why a shut district is shut: its rumour (geography.json's `lockedText`)
/// and the quest that opens it, in a sheet over the plan.
Future<void> showLockedDistrictSheet(
    BuildContext context, DistrictStanding standing,
    {required String name}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _LockedDistrictSheet(standing: standing, name: name),
  );
}

class _LockedDistrictSheet extends ConsumerWidget {
  const _LockedDistrictSheet({required this.standing, required this.name});

  final DistrictStanding standing;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final french = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final quests = ref.watch(gameDbProvider(questsSchema)).value;
    final Map<String, dynamic> record = quests?[standing.lockQuest] ?? const {};
    var questTitle = record['questName']?.toString() ?? '';
    if (french) {
      final fr = record['questName_fr']?.toString() ?? '';
      if (fr.trim().isNotEmpty) questTitle = fr;
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
            key: Key('district_locked_sheet_${standing.id}'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.lock_outline, size: 20, color: ink.ash),
                const SizedBox(width: 8),
                Expanded(child: Text(name, style: theme.textTheme.titleMedium)),
              ]),
              const SizedBox(height: 10),
              Text(standing.lockedText,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic)),
              if (questTitle.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                    trFor(ref.watch(appLanguageProvider), 'district_locked_by')
                        .replaceAll('{quest}', questTitle),
                    key: Key('district_locked_by_${standing.id}'),
                    style:
                        theme.textTheme.labelMedium?.copyWith(color: ink.ash)),
              ],
            ]),
      ),
    );
  }
}
