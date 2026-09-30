import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_conditions.dart';
import '../data/journey_rules.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/camp_presence_provider.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import 'camp_fate_dialog.dart';
import 'immersive_notice.dart';

/// A night's rest in a town, a port or the camp (see
/// PlayerSessionNotifier.restNight), said in a notice: [message], and from
/// chapter 2 the day that begins. A night at the camp ([atCamp]) rolls the
/// camp's fate die (see camp_fate_dialog.dart), which says it instead.
Future<void> restTheNight(BuildContext context, WidgetRef ref,
    {required String message, bool atCamp = false}) async {
  final chapter = ref.read(reachedChapterProvider);
  await ref.read(playerSessionProvider.notifier).restNight(chapter: chapter);
  if (!context.mounted) return;
  final day = ref.read(playerSessionProvider).day;
  final line = roadRulesApply(chapter)
      ? '$message ${tr(ref, 'rest_new_day').replaceAll('{day}', '$day')}'
      : message;
  if (atCamp) {
    await showCampFateDie(context, ref, restedLine: line);
    return;
  }
  showImmersiveNotice(
    context,
    icon: Icons.local_fire_department,
    message: line,
  );
}

/// The road's state and its trade (see journey_rules.dart): the day and
/// how long the chapter has taken (and what that has done to its enemies),
/// the rations carried, with rations to buy and a sellsword to hire while
/// the story stands in a town, a village or the camp. Nothing in chapter
/// 1, whose roads cost nothing.
class RoadPanel extends ConsumerWidget {
  const RoadPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapter = ref.watch(reachedChapterProvider);
    if (!roadRulesApply(chapter)) return const SizedBox.shrink();
    final session = ref.watch(playerSessionProvider);
    final market = ref.watch(atMarketProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final notifier = ref.read(playerSessionProvider.notifier);
    final threat = session.threatIn(chapter);
    final daysHere = session.clockChapter == chapter
        ? session.day - session.chapterStartDay
        : 0;
    // The chapter's condition (see chapter_conditions.dart): what the
    // region is going through, and what it does to the road's numbers.
    final condition = ref.watch(chapterConditionProvider);
    final french = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final price =
        conditionedPrice(provisionPrice(chapter), condition?.rationPrice ?? 1);
    final room = provisionsMax - session.provisions;
    final hire = sellswordPrice(chapter);
    final small = theme.textTheme.bodySmall?.copyWith(color: ink.ash);

    Widget line(IconData icon, String title, String detail, {Color? tint}) =>
        ListTile(
          dense: true,
          leading: Icon(icon, size: 20, color: tint),
          title: Text(title),
          subtitle: Text(detail, style: small),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(tr(ref, 'road_title').toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2, color: theme.colorScheme.primary)),
        ),
        if (condition != null)
          KeyedSubtree(
            key: const ValueKey('road_condition_line'),
            child: line(
              Icons.flag_outlined,
              tr(ref, 'condition_line')
                  .replaceAll('{name}', condition.nameFor(french)),
              condition.effectFor(french),
              tint: ink.gold,
            ),
          ),
        line(
          Icons.wb_sunny_outlined,
          tr(ref, 'road_day_line')
              .replaceAll('{day}', '${session.day}')
              .replaceAll('{n}', '$daysHere'),
          threat > 0
              ? tr(ref, 'road_threat_on')
                  .replaceAll('{p}', '${(threat * 100).round()}')
              : tr(ref, 'road_threat_off')
                  .replaceAll('{n}', '${threatGraceDaysFor(chapter)}'),
          tint: threat > 0 ? theme.colorScheme.error : ink.gold,
        ),
        line(
          Icons.restaurant,
          tr(ref, 'road_rations_line')
              .replaceAll('{n}', '${session.provisions}')
              .replaceAll('{max}', '$provisionsMax'),
          tr(ref, 'road_rations_help'),
          tint: session.provisions == 0 ? theme.colorScheme.error : ink.ash,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              OutlinedButton(
                key: const ValueKey('road_buy_one'),
                onPressed: market && room > 0 && session.gold >= price
                    ? () => notifier.buyProvisions(1, price: price)
                    : null,
                child: Text(
                    tr(ref, 'road_buy_one').replaceAll('{gold}', '$price')),
              ),
              OutlinedButton(
                key: const ValueKey('road_fill_up'),
                onPressed: market && room > 1 && session.gold >= price * room
                    ? () => notifier.buyProvisions(room, price: price)
                    : null,
                child: Text(tr(ref, 'road_fill_up')
                    .replaceAll('{gold}', '${price * room}')),
              ),
            ],
          ),
        ),
        line(
          Icons.shield_moon_outlined,
          session.sellswordFights > 0
              ? tr(ref, 'road_sellsword_hired')
                  .replaceAll('{n}', '${session.sellswordFights}')
              : tr(ref, 'road_sellsword_line'),
          tr(ref, 'road_sellsword_help')
              .replaceAll('{n}', '$sellswordContractFights')
              .replaceAll('{dmg}', '${sellswordDamage(chapter)}'),
          tint: ink.ash,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              key: const ValueKey('road_hire_sellsword'),
              onPressed:
                  market && session.sellswordFights == 0 && session.gold >= hire
                      ? () => notifier.hireSellsword(price: hire)
                      : null,
              child: Text(
                  tr(ref, 'road_hire_sellsword').replaceAll('{gold}', '$hire')),
            ),
          ),
        ),
        if (!market)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(tr(ref, 'road_market_hint'), style: small),
          ),
      ],
    );
  }
}
