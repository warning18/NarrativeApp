import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/dice_faces.dart' show skillDisplayName;
import '../data/factions.dart';
import '../data/item_origin_here.dart';
import '../data/offers.dart';
import '../data/perks.dart';
import '../data/signs.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/offers_provider.dart';
import '../providers/player_session_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import 'item_stats.dart';
import 'pixel_banner.dart';
import 'sign_widgets.dart';
import 'wind_banner.dart';

/// The Wayfarer's colour and mark: no banner, a walker's.
const Color wayfarerColor = Color(0xFF8D6E63);
const int _wayfarerGreetings = 4;

/// Opens the offer when one is due (see offers.dart): after a level-up's
/// dialog, after a boss, at a chapter's start, from the Character tab.
/// The offer is drawn once and kept, so closing the dialog ("Later")
/// never loses or redraws it. [sayWhenNone]: when nobody can come yet,
/// say so (the Character tab's button) rather than nothing (after a
/// fight).
Future<void> showOfferIfWaiting(BuildContext context, WidgetRef ref,
    {bool sayWhenNone = false}) async {
  if (ref.read(playerSessionProvider).pendingOffers.isEmpty) return;
  final tables = await loadOfferTables(ref);
  final offer =
      await ref.read(playerSessionProvider.notifier).ensureOffer(tables);
  if (!context.mounted) return;
  if (offer == null) {
    if (sayWhenNone) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr(ref, 'offer_none_to_come'))));
    }
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (_) => OfferDialog(tables: tables),
  );
}

/// The suitor's name as the card says it: "The Emberwives of the Cinder
/// Compact" for a clan's voice, the faction's name for the others, "The
/// Wayfarer", and "Your own hand" for the lost clan (v1.195).
String suitorName(Suitor suitor, ClanData data, AppLanguage lang) {
  if (suitor.isWayfarer) return trFor(lang, 'offer_wayfarer_name');
  final faction = data.faction(suitor.factionId);
  if (faction?.isLost ?? false) return trFor(lang, 'offer_own_hand_name');
  final voice = data.subclan(suitor.subclanId);
  if (faction == null) return suitor.factionId;
  if (voice == null) return faction.nameFor(lang);
  return '${voice.nameFor(lang)} ${faction.nameOfFor(lang)}';
}

/// What the suitor says: their intro the first time, else a greeting.
String suitorGreeting(Suitor suitor, ClanData data, AppLanguage lang) {
  if (suitor.isWayfarer) {
    return suitor.firstMeeting
        ? trFor(lang, 'offer_wayfarer_intro')
        : trFor(lang,
            'offer_wayfarer_greeting_${suitor.greetingIndex % _wayfarerGreetings}');
  }
  if (data.faction(suitor.factionId)?.isLost ?? false) {
    return trFor(lang, 'offer_own_hand_greeting');
  }
  final patron = data.faction(suitor.factionId)?.patron;
  if (patron == null) return '';
  if (suitor.firstMeeting && patron.introFor(lang).isNotEmpty) {
    return patron.introFor(lang);
  }
  return patron.greetingFor(lang, suitor.greetingIndex);
}

/// The tag over a gift: its kind, or "Fusion" / "Ascension" for a skill
/// that is one (v1.232).
String _giftTagKey(OfferGift gift, Map<String, dynamic> skills) {
  if (gift.kind == GiftKind.skill) {
    final skill = skills[gift.id];
    if (skill is Map<String, dynamic>) {
      if (skill['fusionOf'] is List) return 'offer_gift_fusion';
      if ((skill['subclanId']?.toString() ?? '').isNotEmpty) {
        return 'offer_gift_subclan';
      }
      if (skill['hiddenFlags'] is List) return 'offer_gift_secret';
      if ((skill['ascendsSkillID']?.toString() ?? '').isNotEmpty) {
        return 'offer_gift_ascension';
      }
    }
  }
  return 'offer_gift_${gift.kind.name}';
}

/// The gift's name in [lang].
String giftName(
  OfferGift gift, {
  required OfferTables tables,
  required Map<String, dynamic> localizedItems,
  required AppLanguage lang,
}) {
  switch (gift.kind) {
    case GiftKind.skill:
      return skillDisplayName(gift.id, language: lang);
    case GiftKind.sign:
      return tables.signs[gift.id]?.nameFor(lang) ?? gift.id;
    case GiftKind.object:
      return (localizedItems[gift.id] as Map?)?['itemName']?.toString() ??
          gift.id;
    case GiftKind.title:
      return tables.data.titles[gift.id]?.nameFor(lang) ?? gift.id;
    case GiftKind.sworn:
      return tables.data.faction(gift.id)?.sworn?.nameFor(lang) ?? gift.id;
    case GiftKind.perk:
      final perk = perkFromName(gift.id);
      return perk == null ? gift.id : trFor(lang, perkNameKey(perk));
  }
}

/// The name of the gift whose id an offer's log cause carries
/// (`offer:<gift id>`, see offerCause), whatever kind it was: a title, a
/// sign, an object, a perk, a Sworn boon or a skill. Null when [id] names
/// none of them.
String? offerGiftLabel(
  String id, {
  required OfferTables tables,
  required Map<String, dynamic> localizedItems,
  required AppLanguage lang,
}) {
  final title = tables.data.titles[id];
  if (title != null) return title.nameFor(lang);
  final sign = tables.signs[id];
  if (sign != null) return sign.nameFor(lang);
  final item = localizedItems[id];
  if (item is Map && item['itemName'] != null) {
    return item['itemName'].toString();
  }
  final perk = perkFromName(id);
  if (perk != null) return trFor(lang, perkNameKey(perk));
  final boon = tables.data.faction(id)?.sworn;
  if (boon != null) return boon.nameFor(lang);
  if (tables.skills.containsKey(id)) {
    return skillDisplayName(id, language: lang);
  }
  return null;
}

/// The standing [suitor] would move, as one line: "+6 Compact · +1.5 Mire
/// · −3 Penitents" -- the faction taken first, then the allies' gains and
/// the rivals' losses, the biggest first, in the data's order.
List<({String text, double delta})> standingPreviewParts(
  Suitor suitor,
  OfferTicket ticket, {
  required PoliticsState politics,
  required ClanData data,
  required AppLanguage lang,
  Iterable<String> flags = const [],
}) {
  final order = data.factions.keys.toList();
  int rank(String id) {
    final i = order.indexOf(id);
    return i < 0 ? order.length : i;
  }

  final deltas = suitorPreview(suitor, ticket,
          politics: politics, data: data, flags: flags)
      .entries
      .toList()
    ..sort((a, b) {
      if (a.key == suitor.factionId) return -1;
      if (b.key == suitor.factionId) return 1;
      if ((a.value > 0) != (b.value > 0)) return a.value > 0 ? -1 : 1;
      final bySize = b.value.abs().compareTo(a.value.abs());
      return bySize != 0 ? bySize : rank(a.key).compareTo(rank(b.key));
    });
  return [
    for (final e in deltas)
      (
        // A no-break space: "+6 Compact" never splits across lines.
        text: '${formatStandingDelta(e.value, language: lang)}\u00a0'
            '${data.faction(e.key)?.shortFor(lang) ?? e.key}',
        delta: e.value,
      ),
  ];
}

/// The alignment [suitor]'s gift moves: the faction's or sub-clan's lean,
/// and a vow's or a pact's ±3.
int alignmentNudgeOf(Suitor suitor, OfferTables tables) {
  final sign =
      suitor.gift.kind == GiftKind.sign ? tables.signs[suitor.gift.id] : null;
  return leanOf(suitor, tables.data) +
      (sign == null ? 0 : alignmentShiftFor(sign));
}

/// The offer on the table: three suitors, one card each, stacked (it fits
/// a 360 px phone). A tap picks a card, "Take this gift" asks to confirm
/// it; the next offer follows while more are due.
class OfferDialog extends ConsumerStatefulWidget {
  const OfferDialog({super.key, required this.tables});

  final OfferTables tables;

  @override
  ConsumerState<OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends ConsumerState<OfferDialog> {
  String? _selected;
  bool _busy = false;

  Future<void> _take(ClanOffer offer) async {
    final factionId = _selected;
    final suitor = factionId == null ? null : offer.suitorOf(factionId);
    if (suitor == null || _busy) return;
    final lang = ref.read(appLanguageProvider);
    final tables = widget.tables;
    final items = ref.read(localizedDbProvider(itemsSchema)).value ?? const {};
    final name = giftName(suitor.gift,
        tables: tables, localizedItems: items, lang: lang);
    final preview = standingPreviewParts(suitor, offer.ticket,
        politics: ref.read(playerSessionProvider).politics,
        data: tables.data,
        lang: lang);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:
            Text(trFor(lang, 'offer_confirm_title').replaceAll('{gift}', name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trFor(lang, 'offer_confirm_from')
                .replaceAll('{who}', suitorName(suitor, tables.data, lang))),
            const SizedBox(height: 8),
            Text(preview.isEmpty
                ? trFor(lang, 'offer_no_standing')
                : preview.map((p) => p.text).join(' · ')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(trFor(lang, 'offer_confirm_back')),
          ),
          FilledButton(
            key: const Key('offer_confirm_accept'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(trFor(lang, 'offer_confirm_accept')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final notifier = ref.read(playerSessionProvider.notifier);
    await notifier.acceptSuitor(suitor.factionId,
        tables: tables, origin: itemOriginHere(ref));
    final next = await notifier.ensureOffer(tables);
    if (!mounted) return;
    if (next == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final offer = session.clanOffer;
    if (offer == null) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(heightFactor: 1, child: CircularProgressIndicator()),
        ),
      );
    }
    final ticket = offer.ticket;
    final source = trFor(lang, 'offer_source_${ticket.source.name}')
        .replaceAll('{n}', ticket.detail);
    final waiting = session.pendingOffers.length;
    final selected = _selected == null ? null : offer.suitorOf(_selected!);
    final accent = selected == null
        ? theme.colorScheme.primary
        : _suitorColor(selected, widget.tables.data);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      clipBehavior: Clip.antiAlias,
      // The first offer's tour (the topic Signs had, see tutorial_topics).
      child: TutorialTrigger(
        topic: TutorialTopic.signs,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TutorialTarget(
              id: 'signs.patron',
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                color: theme.colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(Icons.diversity_3, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trFor(lang, 'offer_title'),
                            key: const Key('offer_title'),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            waiting > 1
                                ? '$source · ${trFor(lang, 'offer_pending').replaceAll('{n}', '$waiting')}'
                                : source,
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                child: TutorialTarget(
                  id: 'signs.cards',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        trFor(lang, 'offer_hint'),
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 10),
                      // One little flag for each suitor, with what it gives.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final suitor in offer.suitors)
                            Expanded(
                              child: _OfferFlag(
                                key: Key('offer_suitor_${suitor.factionId}'),
                                suitor: suitor,
                                ticket: ticket,
                                tables: widget.tables,
                                selected: _selected == suitor.factionId,
                                dimmed: _selected != null &&
                                    _selected != suitor.factionId,
                                onTap: _busy
                                    ? null
                                    : () => setState(
                                        () => _selected = suitor.factionId),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // The chosen banner's words, in a zone of one size so
                      // nothing moves when another banner is picked; a hint
                      // while none is.
                      SizedBox(
                        key: const Key('offer_detail_zone'),
                        height: 250,
                        child: selected != null
                            ? SingleChildScrollView(
                                child: SuitorCard(
                                  key: Key(
                                      'offer_summary_${selected.factionId}'),
                                  suitor: selected,
                                  ticket: ticket,
                                  tables: widget.tables,
                                ),
                              )
                            : Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.touch_app_outlined,
                                        size: 18,
                                        color:
                                            theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        trFor(lang, 'offer_select_hint'),
                                        key: const Key('offer_select_hint'),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              // Side by side when they fit, stacked on a narrow phone.
              child: OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed:
                        _busy ? null : () => Navigator.of(context).maybePop(),
                    child: Text(trFor(lang, 'offer_later_button')),
                  ),
                  FilledButton(
                    key: const Key('offer_take_button'),
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    onPressed:
                        selected == null || _busy ? null : () => _take(offer),
                    child: Text(trFor(lang, 'offer_take_button')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A suitor as a little flag: their banner (a Wayfarer's plain pennant), the
/// kind and name of the gift under it, its rarity, and the first standing it
/// moves. Every banner is the same size, picked or not (v1.267); a tap picks
/// the flag, and its banner takes the wind. The rest is told in the zone
/// under the flags.
class _OfferFlag extends ConsumerWidget {
  const _OfferFlag({
    super.key,
    required this.suitor,
    required this.ticket,
    required this.tables,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final Suitor suitor;
  final OfferTicket ticket;
  final OfferTables tables;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    final session = ref.watch(playerSessionProvider);
    final items = ref.watch(localizedDbProvider(itemsSchema)).value ?? const {};
    final skills =
        ref.watch(localizedDbProvider(skillsSchema)).value ?? const {};
    final data = tables.data;
    final color = _suitorColor(suitor, data);
    final gift = suitor.gift;
    final name =
        giftName(gift, tables: tables, localizedItems: items, lang: lang);
    final preview = standingPreviewParts(suitor, ticket,
        politics: session.politics,
        data: data,
        lang: lang,
        flags: session.flags);
    final bannerId = suitor.isWayfarer ? null : clanBannerId(suitor.factionId);
    final who = suitorName(suitor, data, lang);
    const good = Color(0xFF3E9B57);

    // One box for every banner, so none changes size when another is picked
    // (the picked one only takes the wind).
    final bannerBox = (pixelBannerSize.width + 2 * WindBanner.room).toDouble();
    final Widget flag = bannerId == null
        ? _PlainFlag(color: color, wayfarer: suitor.isWayfarer)
        : SizedBox(
            key: Key('offer_banner_${suitor.factionId}'),
            width: bannerBox,
            height: pixelBannerSize.height.toDouble(),
            child: selected
                ? WindBanner(id: bannerId, scale: 1)
                : Center(child: PixelBanner(id: bannerId, scale: 1)),
          );

    return Semantics(
      button: true,
      selected: selected,
      label: '$who: $name',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: dimmed ? 0.62 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: selected ? color : Colors.transparent, width: 2),
                    color: selected ? color.withValues(alpha: 0.12) : null,
                  ),
                  child: Center(child: flag),
                ),
                const SizedBox(height: 6),
                _Tag(
                    text: trFor(lang, _giftTagKey(gift, skills)), color: color),
                const SizedBox(height: 4),
                Text(
                  name,
                  key: Key('offer_gift_${gift.id}'),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                if (gift.kind != GiftKind.perk) ...[
                  const SizedBox(height: 4),
                  SignRarityChip(rarity: gift.rarity, language: lang),
                ],
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    preview.first.text,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: preview.first.delta >= 0
                            ? good
                            : theme.colorScheme.error,
                        fontWeight: FontWeight.w600),
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

/// A flag with no banner of its own (the Wayfarer's, or a clan without one):
/// dark cloth under a rod, a band and a mark in the suitor's colour, and a
/// swallowtail hem.
class _PlainFlag extends StatelessWidget {
  const _PlainFlag({required this.color, required this.wayfarer});

  final Color color;
  final bool wayfarer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 128,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 10,
            child: ClipPath(
              clipper: const _SwallowtailClipper(),
              child: Container(
                width: 56,
                height: 114,
                color: const Color(0xFF141217),
                child: Column(
                  children: [
                    Container(height: 4, color: color),
                    const Spacer(),
                    Icon(wayfarer ? Icons.hiking : Icons.flag,
                        size: 30, color: const Color(0xFFEFE6D2)),
                    const SizedBox(height: 14),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            child: Container(
              width: 76,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF8A6B2F),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwallowtailClipper extends CustomClipper<Path> {
  const _SwallowtailClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(size.width / 2, size.height - 16)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_SwallowtailClipper old) => false;
}

Color _suitorColor(Suitor suitor, ClanData data) => suitor.isWayfarer
    ? wayfarerColor
    : Color(data.faction(suitor.factionId)?.color ?? 0xFFB08D3C);

/// One suitor's card: their colour and mark, "The Emberwives of the Cinder
/// Compact", what they say, the gift (its kind, name, rarity and what it
/// does) and the standing it would move, faction by faction, from the
/// relations as they stand.
class SuitorCard extends ConsumerWidget {
  const SuitorCard({
    super.key,
    required this.suitor,
    required this.ticket,
    required this.tables,
    this.selected = false,
    this.onTap,
  });

  final Suitor suitor;
  final OfferTicket ticket;
  final OfferTables tables;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    final session = ref.watch(playerSessionProvider);
    final items = ref.watch(localizedDbProvider(itemsSchema)).value ?? const {};
    final skills =
        ref.watch(localizedDbProvider(skillsSchema)).value ?? const {};
    final data = tables.data;
    final faction = data.faction(suitor.factionId);
    final color = _suitorColor(suitor, data);
    final gift = suitor.gift;
    final greeting = suitorGreeting(suitor, data, lang);
    final preview = standingPreviewParts(suitor, ticket,
        politics: session.politics,
        data: data,
        lang: lang,
        flags: session.flags);
    final nudge = alignmentNudgeOf(suitor, tables);
    // A lost clan has no standing to show (v1.195).
    final tier = faction == null || faction.isLost
        ? null
        : session.politics.tierOf(suitor.factionId, data);
    const good = Color(0xFF3E9B57);
    final bad = theme.colorScheme.error;

    final emblem = suitor.isWayfarer
        ? Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: wayfarerColor.withValues(alpha: 0.85),
            ),
            child: const Icon(Icons.hiking, size: 20, color: Colors.white),
          )
        : PatronEmblem(patron: faction?.patron, size: 36);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? color : theme.colorScheme.outlineVariant,
          width: selected ? 2.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The suitor, on a band of their colour.
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  color.withValues(alpha: 0.32),
                  color.withValues(alpha: 0.06),
                ]),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  emblem,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suitorName(suitor, data, lang),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (tier != null)
                          Text(
                            trFor(lang, standingTierKey(tier)),
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: Color(tierColor(tier)),
                                fontWeight: FontWeight.w600),
                          ),
                        if (greeting.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              greeting,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // The gift.
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Tag(
                        text: trFor(lang, _giftTagKey(gift, skills)),
                        color: color,
                      ),
                      Text(
                        giftName(gift,
                            tables: tables, localizedItems: items, lang: lang),
                        key: Key('offer_gift_${gift.id}'),
                        style: theme.textTheme.titleSmall,
                      ),
                      if (gift.kind != GiftKind.perk)
                        SignRarityChip(rarity: gift.rarity, language: lang),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _GiftBody(
                    gift: gift,
                    tables: tables,
                    items: items,
                    skills: skills,
                    session: session,
                    lang: lang,
                  ),
                  const SizedBox(height: 6),
                  // The standing it moves, and the alignment.
                  Text.rich(
                    TextSpan(children: [
                      if (preview.isEmpty)
                        TextSpan(text: trFor(lang, 'offer_no_standing')),
                      for (var i = 0; i < preview.length; i++) ...[
                        if (i > 0) const TextSpan(text: ' · '),
                        TextSpan(
                          text: preview[i].text,
                          style: TextStyle(
                              color: preview[i].delta >= 0 ? good : bad,
                              fontWeight:
                                  i == 0 ? FontWeight.bold : FontWeight.w500),
                        ),
                      ],
                      if (nudge != 0) ...[
                        const TextSpan(text: ' · '),
                        TextSpan(
                          text: trFor(lang, 'offer_alignment_nudge').replaceAll(
                              '{n}', nudge > 0 ? '+$nudge' : '−${-nudge}'),
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ]),
                    key: Key('offer_preview_${suitor.factionId}'),
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.7)),
        ),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
}

/// What a gift does, in its own words: a sign's effect lines (and what it
/// would replace), a skill's line, an object's stats, a title's or a
/// boon's effects, a perk's description.
class _GiftBody extends StatelessWidget {
  const _GiftBody({
    required this.gift,
    required this.tables,
    required this.items,
    required this.skills,
    required this.session,
    required this.lang,
  });

  final OfferGift gift;
  final OfferTables tables;
  final Map<String, dynamic> items;
  final Map<String, dynamic> skills;
  final PlayerSession session;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall;
    final muted = small?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    Widget lines(Iterable<String> texts, {TextStyle? style}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final t in texts)
              if (t.trim().isNotEmpty) Text(t, style: style ?? small),
          ],
        );
    switch (gift.kind) {
      case GiftKind.sign:
        final sign = tables.signs[gift.id];
        if (sign == null) return const SizedBox.shrink();
        final replaces = heldInSlot(sign.slot, session.heldSigns, tables.signs);
        final replaced =
            replaces == null ? null : tables.signs[replaces.signId];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trFor(lang, signSlotKey(sign.slot)), style: muted),
            SignEffectText(
              sign: sign,
              rarity: gift.rarity,
              level: replaces?.level ?? 1,
              language: lang,
            ),
            if (replaced != null)
              Text(
                trFor(lang, 'sign_replaces')
                    .replaceAll('{name}', replaced.nameFor(lang)),
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600),
              ),
          ],
        );
      case GiftKind.skill:
        final skill = skills[gift.id] as Map<String, dynamic>?;
        final parents = [
          for (final p in (skill?['fusionOf'] as List?) ?? const [])
            skillDisplayName(p.toString(), language: lang),
        ];
        final base = skill?['ascendsSkillID']?.toString() ?? '';
        final partner = tables.data.faction(gift.partnerId)?.shortFor(lang);
        return lines([
          if (parents.length == 2)
            trFor(lang, 'offer_fusion_line')
                .replaceAll('{a}', parents[0])
                .replaceAll('{b}', parents[1])
                .replaceAll('{clan}', partner ?? ''),
          if (skill?['hiddenFlags'] is List) trFor(lang, 'offer_secret_line'),
          if (base.isNotEmpty)
            trFor(lang, 'offer_ascension_line')
                .replaceAll('{skill}', skillDisplayName(base, language: lang)),
          skill?['description']?.toString() ?? '',
        ]);
      case GiftKind.object:
        final item = items[gift.id] as Map<String, dynamic>?;
        final stats = [
          for (final line in gearStatLines(item, null, lang))
            '${line.label} ${line.value > 0 ? '+' : ''}${line.value}',
        ];
        return lines([
          if (stats.isNotEmpty) stats.join(' · '),
          ...itemTraitNotes(item, lang),
          if (consumableNote(gift.id, item, lang) case final note?) note,
          if (item?['description'] case final description?) '$description',
        ]);
      case GiftKind.title:
        final title = tables.data.titles[gift.id];
        if (title == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            lines([for (final e in title.effects) signEffectText(e, lang)]),
            if (title.lineFor(lang).isNotEmpty)
              Text(title.lineFor(lang),
                  style: muted?.copyWith(fontStyle: FontStyle.italic)),
          ],
        );
      case GiftKind.sworn:
        final boon = tables.data.faction(gift.id)?.sworn;
        if (boon == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            lines([for (final e in boon.effects) signEffectText(e, lang)]),
            if (boon.lineFor(lang).isNotEmpty)
              Text(boon.lineFor(lang),
                  style: muted?.copyWith(fontStyle: FontStyle.italic)),
            Text(trFor(lang, 'offer_sworn_note'), style: muted),
          ],
        );
      case GiftKind.perk:
        final perk = perkFromName(gift.id);
        if (perk == null) return const SizedBox.shrink();
        final rank = (session.perkRanks[gift.id] ?? 0) + 1;
        return lines([
          trFor(lang, perkDescKey(perk)),
          if (perkInfo[perk]!.maxRank > 1)
            trFor(lang, 'perk_rank')
                .replaceAll('{n}', '$rank')
                .replaceAll('{max}', '${perkInfo[perk]!.maxRank}'),
        ]);
    }
  }
}
