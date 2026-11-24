// The pop-in "Play to chapter" opens when its walk ends (autoplay_summary.dart):
// one tab each for the state, the choices, the items, the banners, the
// fights and the companions. Plain lists; the look is UX's to polish.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/autoplay_summary.dart';
import '../data/factions.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';

/// Shows [summary]. [clans] names the clans; [itemName] and
/// [companionName] name an item or a companion by its id (the id itself
/// when unknown).
Future<void> showAutoplaySummary(
  BuildContext context, {
  required AutoplaySummary summary,
  required ClanData clans,
  required String Function(String itemId) itemName,
  required String Function(String companionId) companionName,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => AutoplaySummaryDialog(
        summary: summary,
        clans: clans,
        itemName: itemName,
        companionName: companionName,
      ),
    );

class AutoplaySummaryDialog extends ConsumerWidget {
  const AutoplaySummaryDialog({
    super.key,
    required this.summary,
    required this.clans,
    required this.itemName,
    required this.companionName,
  });

  final AutoplaySummary summary;
  final ClanData clans;
  final String Function(String itemId) itemName;
  final String Function(String companionId) companionName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    String t(String key) => trFor(lang, key);
    String clan(String id) => clans.faction(id)?.nameFor(lang) ?? id;
    final s = summary;

    Widget list(List<Widget> rows) => rows.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: Text(t('ptc_none')),
          )
        : ListView(padding: const EdgeInsets.all(8), children: rows);
    Widget row(String title, [String? subtitle]) => ListTile(
          dense: true,
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
        );
    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(text, style: Theme.of(context).textTheme.labelLarge),
        );

    final tabs = <(String, Widget)>[
      (
        t('ptc_tab_state'),
        list([
          row('${t('ptc_level')} ${s.level}',
              '${s.raceId} · ${s.professionId}'),
          row('${t('ptc_gold')} ${s.gold}'),
          row('${t('ptc_chapter')} ${s.chapter}',
              '${t('ptc_scene')} ${s.nodeId}'),
          header(t('ptc_standings')),
          for (final st in s.standings)
            row(
                clan(st.factionId),
                '${trFor(lang, 'standing_tier_${st.tier.name}')} · '
                '${st.value.round()}'),
        ]),
      ),
      (
        t('ptc_tab_choices'),
        list([
          for (final (i, c) in s.choices.indexed)
            row('${i + 1}. ${c.text}', c.nodeId),
        ]),
      ),
      (
        t('ptc_tab_items'),
        list([
          header(t('ptc_equipped')),
          for (final id in s.equipped) row(itemName(id)),
          header(t('ptc_gained')),
          for (final id in s.gained) row(itemName(id)),
          header(t('ptc_lost')),
          for (final id in s.lost) row(itemName(id)),
        ]),
      ),
      (
        t('ptc_tab_banners'),
        list([
          row(t('ptc_carried_banner'),
              s.carriedBanner.isEmpty ? t('ptc_none') : clan(s.carriedBanner)),
          for (final b in s.banners)
            row(clan(b.factionId),
                '${t('ptc_chapter')} ${b.chapter} · ${b.gift}'),
          if (s.offersWaiting > 0)
            row(t('ptc_offers_waiting'), '${s.offersWaiting}'),
        ]),
      ),
      (
        '${t('ptc_tab_fights')} ${s.fightsWon}/${s.fights.length}',
        list([
          for (final f in s.fights)
            row(
                f.name,
                f.won
                    ? (f.forced ? t('ptc_forced') : t('ptc_won'))
                    : t('ptc_lost_fight')),
        ]),
      ),
      (
        t('ptc_tab_companions'),
        list([
          header(t('ptc_seated')),
          for (final id in s.seated) row(companionName(id)),
          header(t('ptc_recruited')),
          for (final id in s.recruited) row(companionName(id)),
        ]),
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: AlertDialog(
        title: Text(t('ptc_summary_title')),
        contentPadding: const EdgeInsets.only(top: 8),
        content: SizedBox(
          width: 480,
          height: 480,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabs: [for (final (label, _) in tabs) Tab(text: label)],
              ),
              Expanded(
                child: TabBarView(
                  children: [for (final (_, view) in tabs) view],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t('ptc_close')),
          ),
        ],
      ),
    );
  }
}
