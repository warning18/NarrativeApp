// The body of a gift's confirmation (v1.553, "Take {gift}?"): what the player
// is about to decide, not more data. One line for what the gift does, in the
// gift's own words (its sign's or skill's effect); then two short groups of
// clans, "Closer" and "Further", each clan a chip with its crest, its name
// and the change, green up and red down, in whole numbers ("a little" under
// one), and the step word only when the relation crosses a step ("Wary ->
// Hostile"), since that is the consequence a player feels. The offer's
// confirmation uses it (offer_dialog.dart); any other gift's can.
import 'package:flutter/material.dart';

import '../data/factions.dart';
import '../data/offers.dart';
import '../data/perks.dart';
import '../data/signs.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import 'item_stats.dart';
import 'pixel_banner.dart';

/// One clan a gift moves: [delta] points of standing, from the [before] step
/// to the [after] one.
class ClanChange {
  const ClanChange({
    required this.factionId,
    required this.name,
    required this.delta,
    required this.before,
    required this.after,
  });

  final String factionId;
  final String name;
  final double delta;
  final StandingTier before;
  final StandingTier after;

  bool get up => delta > 0;

  /// Whether the change takes the relation to another step.
  bool get crossesStep => before != after;
}

/// The clans [suitor]'s gift moves, the offering clan first, the closer
/// before the further, the biggest change first within each; clans whose
/// standing does not move are left out.
List<ClanChange> clanChangesOf(
  Suitor suitor,
  OfferTicket ticket, {
  required PoliticsState politics,
  required ClanData data,
  required AppLanguage lang,
  Iterable<String> flags = const [],
}) {
  final deltas = suitorPreview(suitor, ticket,
      politics: politics, data: data, flags: flags);
  final order = data.factions.keys.toList();
  int rank(String id) {
    final i = order.indexOf(id);
    return i < 0 ? order.length : i;
  }

  final changes = <ClanChange>[
    for (final e in deltas.entries)
      if (e.value != 0)
        () {
          final from = politics.standingOf(e.key, data);
          final to = (from + e.value)
              .clamp(minStanding.toDouble(), maxStanding.toDouble());
          return ClanChange(
            factionId: e.key,
            name: data.faction(e.key)?.shortFor(lang) ?? e.key,
            delta: e.value,
            before: standingTierFor(from),
            after: standingTierFor(to),
          );
        }(),
  ]..sort((a, b) {
      if (a.up != b.up) return a.up ? -1 : 1;
      if (a.factionId == suitor.factionId) return -1;
      if (b.factionId == suitor.factionId) return 1;
      final bySize = b.delta.abs().compareTo(a.delta.abs());
      return bySize != 0
          ? bySize
          : rank(a.factionId).compareTo(rank(b.factionId));
    });
  return changes;
}

/// A change in words a player reads: "+6", "−3", or "a little" when it is
/// under one (never "+1,5").
String changeText(double delta, AppLanguage lang) {
  final whole = delta.abs().round();
  if (whole == 0) return trFor(lang, 'offer_delta_little');
  return '${delta > 0 ? '+' : '−'}$whole';
}

/// What [gift] does, as one line in its own words: its sign's effect, its
/// skill's description, its object's stats, its title's or boon's effect, its
/// perk's or specialisation's line. Empty when it has none.
String giftEffectLine(
  OfferGift gift, {
  required OfferTables tables,
  required Map<String, dynamic> items,
  required Map<String, dynamic> skills,
  required AppLanguage lang,
}) {
  String join(Iterable<String> parts) =>
      parts.where((p) => p.trim().isNotEmpty).join(' · ');
  switch (gift.kind) {
    case GiftKind.sign:
      final sign = tables.signs[gift.id];
      return sign == null
          ? ''
          : join(signEffectLines(sign, gift.rarity, 1, lang));
    case GiftKind.skill:
      final skill = skills[gift.id] as Map<String, dynamic>?;
      return skill?['description']?.toString() ?? '';
    case GiftKind.object:
      final item = items[gift.id] as Map<String, dynamic>?;
      final stats = [
        for (final line in gearStatLines(item, null, lang))
          '${line.label} ${line.value > 0 ? '+' : ''}${line.value}',
      ];
      return stats.isNotEmpty
          ? stats.join(' · ')
          : item?['description']?.toString() ?? '';
    case GiftKind.title:
      final title = tables.data.titles[gift.id];
      return title == null
          ? ''
          : join([for (final e in title.effects) signEffectText(e, lang)]);
    case GiftKind.sworn:
      final boon = tables.data.faction(gift.id)?.sworn;
      return boon == null
          ? ''
          : join([for (final e in boon.effects) signEffectText(e, lang)]);
    case GiftKind.spec:
      final fr = lang == AppLanguage.fr;
      final spec = tables.specs[gift.id];
      final variant = tables.specVariants[gift.id];
      return spec?.giftFor(fr) ?? variant?.textFor(fr) ?? '';
    case GiftKind.perk:
      final perk = perkFromName(gift.id);
      return perk == null ? '' : trFor(lang, perkDescKey(perk));
  }
}

/// The body: [effect] on a line, then "Closer" and "Further" with a chip for
/// each clan in [changes]. With no [changes] it says [noStanding].
class GiftConfirmBody extends StatelessWidget {
  const GiftConfirmBody({
    super.key,
    required this.effect,
    required this.changes,
    required this.lang,
    required this.noStanding,
  });

  final String effect;
  final List<ClanChange> changes;
  final AppLanguage lang;
  final String noStanding;

  static const Color _good = Color(0xFF3E9B57);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final closer = [
      for (final c in changes)
        if (c.up) c
    ];
    final further = [
      for (final c in changes)
        if (!c.up) c
    ];
    Widget group(String key, List<ClanChange> list, Color colour) {
      if (list.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trFor(lang, key).toUpperCase(),
                key: Key(key),
                style: theme.textTheme.labelSmall?.copyWith(
                    color: colour,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in list)
                _ClanChip(
                    key: Key('gift_change_${c.factionId}'),
                    change: c,
                    lang: lang,
                    colour: colour),
            ]),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (effect.isNotEmpty)
          Text(effect,
              key: const Key('gift_effect_line'),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
        if (changes.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: effect.isEmpty ? 0 : 10),
            child: Text(noStanding,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          )
        else ...[
          group('offer_confirm_closer', closer, _good),
          group('offer_confirm_further', further, theme.colorScheme.error),
        ],
      ],
    );
  }
}

/// One clan: its crest, its name, the change, and the step it crosses.
class _ClanChip extends StatelessWidget {
  const _ClanChip({
    super.key,
    required this.change,
    required this.lang,
    required this.colour,
  });

  final ClanChange change;
  final AppLanguage lang;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color tier(StandingTier t) => Color(tierColor(t) | 0xFF000000);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colour.withValues(alpha: 0.7)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        ClanFlag(factionId: change.factionId, height: 26),
        const SizedBox(width: 6),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(change.name, style: theme.textTheme.bodyMedium),
              const SizedBox(width: 6),
              Icon(change.up ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14, color: colour),
              Text(changeText(change.delta, lang),
                  key: Key('gift_change_text_${change.factionId}'),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colour, fontWeight: FontWeight.w700)),
            ]),
            // The consequence a player feels: the relation changing step.
            if (change.crossesStep)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(trFor(lang, standingTierKey(change.before)),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: tier(change.before))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_right_alt,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(trFor(lang, standingTierKey(change.after)),
                    key: Key('gift_step_${change.factionId}'),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: tier(change.after),
                        fontWeight: FontWeight.w700)),
              ]),
          ],
        ),
      ]),
    );
  }
}
