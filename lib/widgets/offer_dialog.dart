import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/dice_faces.dart' show skillDisplayName;
import '../combat/specialisations.dart' show specId;
import '../data/camp_rolls.dart' show suitorBanishable;
import '../data/factions.dart';
import '../data/item_origin_here.dart';
import '../data/offers.dart';
import '../data/perks.dart';
import '../data/risky_gifts.dart';
import 'risky_roll_dialog.dart';
import '../data/signs.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/offers_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/territory_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/item_icons.dart';
import '../utils/pixel_icons/pixel_icon.dart';
import '../utils/pixel_icons/skill_icons.dart';
import 'clan_compass.dart';
import 'clan_peek.dart';
import 'clan_radar_chart.dart';
import 'item_stats.dart';
import 'pixel_banner.dart';
import 'reward_card.dart';
import 'reward_cards.dart';
import 'roll_power_row.dart';
import 'sign_widgets.dart';
import 'wind_banner.dart';

/// The Wayfarer's colour and mark: no banner, a walker's.
const Color wayfarerColor = Color(0xFF8D6E63);
const int _wayfarerGreetings = 4;

/// Opens the offer when one is due (see offers.dart): after a level-up's
/// dialog, after a boss, at a chapter's start, from the Character tab.
/// The offer is drawn once and kept; it is never left for later (Wave 6):
/// the dialog closes when a gift is taken. [sayWhenNone]: when nobody can come yet,
/// say so (the Character tab's button) rather than nothing (after a
/// fight).
Future<void> showOfferIfWaiting(BuildContext context, WidgetRef ref,
    {bool sayWhenNone = false}) async {
  if (ref.read(playerSessionProvider).pendingOffers.isEmpty) return;
  final tables = await loadOfferTables(ref);
  final offer = await ref
      .read(playerSessionProvider.notifier)
      .ensureOffer(tables, placeHolder: ref.read(holderHereProvider));
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
    barrierDismissible: false,
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
    case GiftKind.spec:
      return tables.specs[gift.id]?.nameFor(lang == AppLanguage.fr) ??
          tables.specVariants[gift.id]?.nameFor(lang == AppLanguage.fr) ??
          gift.id;
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
  final spec = tables.specs[id];
  if (spec != null) return spec.nameFor(lang == AppLanguage.fr);
  final variant = tables.specVariants[id];
  if (variant != null) return variant.nameFor(lang == AppLanguage.fr);
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
    final odds = ref.read(playerSessionProvider.notifier).riskyOdds(tables);
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
            if (suitor.risky) ...[
              const SizedBox(height: 8),
              Text(trFor(lang, 'offer_risky_hint')),
              Text(
                  trFor(lang, 'offer_risky_odds')
                      .replaceAll('{gift}', '${odds.gift}')
                      .replaceAll('{price}', '${odds.price}'),
                  key: const Key('offer_confirm_risky_odds')),
            ],
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
    // A risky card: what the die (rolled with the draw) says, read before
    // it is applied.
    final risk = notifier.riskyResultOf(suitor, tables);
    // ... and the die rolled in front of the player before it is applied.
    if (risk != null && mounted) {
      await showRiskyRoll(context,
          roll: suitor.riskRoll,
          luck: notifier.riskyLuck(tables),
          won: risk.won,
          lang: lang);
    }
    await notifier.acceptSuitor(suitor.factionId,
        tables: tables, origin: itemOriginHere(ref));
    // The gift, as the reward card tells it, before the next offer.
    if (mounted) {
      final skills =
          ref.read(localizedDbProvider(skillsSchema)).value ?? const {};
      final clanColour = _suitorColor(suitor, tables.data);
      final card = clanGiftCard(
        lang: lang,
        clanName: suitorName(suitor, tables.data, lang),
        clanColour: clanColour,
        gift: risk != null && !risk.won
            // The price paid: the line says what the die took.
            ? RewardLine(
                key: Key('reward_risky_${risk.outcome.name}'),
                icon: Icon(Icons.casino_outlined, color: clanColour),
                accent: clanColour,
                title: riskyResultText(
                    risk, tables.data.faction(suitor.factionId), lang),
                sub: name,
                tag: trFor(lang, 'offer_risky_badge'),
              )
            : RewardLine(
                key: Key('reward_gift_${suitor.gift.id}'),
                icon: _giftGlyph(suitor.gift, clanColour),
                accent: clanColour,
                title: name,
                sub: trFor(lang, _giftTagKey(suitor.gift, skills)),
                value: trFor(lang, 'reward_new'),
              ),
        standing: [for (final p in preview) p.text],
      );
      await showRewardCard(
        context,
        risk == null || !risk.won
            ? card
            : RewardCardData(
                kind: card.kind,
                title: card.title,
                accent: card.accent,
                button: card.button,
                lines: card.lines,
                notes: [
                  RewardNote(riskyResultText(
                      risk, tables.data.faction(suitor.factionId), lang)),
                  ...card.notes,
                ],
              ),
      );
    }
    final next = await notifier.ensureOffer(tables,
        placeHolder: ref.read(holderHereProvider));
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

  /// A roll power (camp_rolls.dart) used on the offer on the table; the
  /// selection kept only for a raise.
  Future<void> _roll(Future<void> Function() use, {bool keep = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await use();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          if (!keep) _selected = null;
        });
      }
    }
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

    // An offer is never left for later (Wave 6): a gift is taken to close it.
    return PopScope(
      canPop: false,
      child: Dialog(
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
              // The three banners on top, then the clans' compass, then the
              // picked banner's words. It scrolls; the button below does not.
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                  child: TutorialTarget(
                    id: 'signs.cards',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final suitor in offer.suitors)
                              Expanded(
                                child: _OfferBanner(
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
                        ConstrainedBox(
                          key: const Key('offer_detail_zone'),
                          constraints: const BoxConstraints(minHeight: 280),
                          child: _OfferHall(
                            key: selected == null
                                ? const Key('offer_hall_none')
                                : Key('offer_summary_${selected.factionId}'),
                            offer: offer,
                            suitor: selected,
                            tables: widget.tables,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The camp's roll houses (camp_rolls.dart).
                    RollPowerRow(
                      keyPrefix: 'offer',
                      rolls: ref.watch(campRollsProvider),
                      canBanish:
                          selected != null && suitorBanishable(selected, offer),
                      canRaise: selected != null &&
                          ref.read(playerSessionProvider.notifier).raisePreview(
                                  selected.factionId, widget.tables) !=
                              null,
                      warnRaised: offer.suitors.any((s) => s.raised),
                      onReroll: () => _roll(() => ref
                          .read(playerSessionProvider.notifier)
                          .rerollOffer(widget.tables,
                              placeHolder: ref.read(holderHereProvider))),
                      onBanish: (draws) => _roll(() => ref
                          .read(playerSessionProvider.notifier)
                          .banishSuitor(
                              selected!.factionId, draws, widget.tables,
                              placeHolder: ref.read(holderHereProvider))),
                      onRaise: () => _roll(
                          () => ref
                              .read(playerSessionProvider.notifier)
                              .raiseSuitor(selected!.factionId, widget.tables),
                          keep: true),
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
      ),
    );
  }
}

/// A suitor as a banner, a little smaller than its pixels (three quarters):
/// the clan's own banner (a Wayfarer's plain pennant) lit in its colour when
/// picked, and the gift under it by kind and name with the first standing it
/// moves. A tap picks it; the compass and the words below tell the rest.
class _OfferBanner extends ConsumerWidget {
  const _OfferBanner({
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
    final faction = data.faction(suitor.factionId);
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
    final Widget inner = bannerId == null
        ? _PlainFlag(color: color, wayfarer: suitor.isWayfarer)
        : SizedBox(
            key: Key('offer_banner_${suitor.factionId}'),
            width: bannerBox,
            height: pixelBannerSize.height.toDouble(),
            child: selected
                ? WindBanner(id: bannerId, scale: 1)
                : Center(child: PixelBanner(id: bannerId, scale: 1)),
          );
    final Widget flag = SizedBox(
      width: bannerBox * 0.75,
      height: pixelBannerSize.height * 0.75,
      child: FittedBox(child: inner),
    );

    return ClanPeek(
      factionId: suitor.isWayfarer ? null : suitor.factionId,
      child: Semantics(
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
                          color: selected ? color : Colors.transparent,
                          width: 2),
                      color: selected ? color.withValues(alpha: 0.12) : null,
                    ),
                    child: Center(child: flag),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suitor.isWayfarer ? who : (faction?.shortFor(lang) ?? who),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  _Tag(
                      text: trFor(lang, _giftTagKey(gift, skills)),
                      color: color),
                  const SizedBox(height: 3),
                  Text(
                    name,
                    key: Key('offer_gift_${gift.id}'),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 3),
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
      ),
    );
  }
}

/// Under the banners: the clans' compass (the picked clan's lines and what
/// changes for each clan, the clans on offer ringed), then the picked
/// suitor's charter (name, where you stand with them, motto, what they stand
/// for, which way the alignment moves, in a word) and the gift with the
/// words the clan says. With none picked, the compass and a hint.
class _OfferHall extends ConsumerWidget {
  const _OfferHall({
    super.key,
    required this.offer,
    required this.suitor,
    required this.tables,
  });

  final ClanOffer offer;
  final Suitor? suitor;
  final OfferTables tables;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    final session = ref.watch(playerSessionProvider);
    final items = ref.watch(localizedDbProvider(itemsSchema)).value ?? const {};
    final skills =
        ref.watch(localizedDbProvider(skillsSchema)).value ?? const {};
    final data = tables.data;
    final politics = session.politics;
    final clanIds = {for (final c in data.clans) c.patron.id};
    final suitors = {
      for (final s in offer.suitors)
        if (!s.isWayfarer && clanIds.contains(s.factionId)) s.factionId,
    };
    final picked = suitor;
    final onRing = picked != null && clanIds.contains(picked.factionId);
    final preview = picked == null
        ? const <String, double>{}
        : suitorPreview(picked, offer.ticket,
            politics: politics, data: data, flags: session.flags);
    const good = Color(0xFF3E9B57);
    final bad = theme.colorScheme.error;
    final compass = ClanCompass(
      clans: data.clans,
      language: lang,
      relations: data.relations,
      stepOf: (a, b) => politics.relationStep(a, b, data),
      height: 176,
      focusId: onRing ? picked.factionId : null,
      ringedIds: suitors,
      badges: {
        for (final e in preview.entries)
          if (clanIds.contains(e.key))
            e.key: (
              text: formatStandingDelta(e.value, language: lang),
              color: e.value >= 0 ? good : bad,
            ),
      },
    );
    if (picked == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          compass,
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.touch_app_outlined,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trFor(lang, 'offer_select_hint'),
                  key: const Key('offer_select_hint'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final faction = data.faction(picked.factionId);
    final color = _suitorColor(picked, data);
    final gift = picked.gift;
    final greeting = suitorGreeting(picked, data, lang);
    final nudge = alignmentNudgeOf(picked, tables);
    final tier = faction == null || faction.isLost
        ? null
        : politics.tierOf(picked.factionId, data);
    final alignKey = nudge > 0
        ? 'offer_align_good'
        : nudge < 0
            ? 'offer_align_evil'
            : 'offer_align_none';
    final alignColor = nudge > 0
        ? good
        : nudge < 0
            ? bad
            : theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        compass,
        if (preview.isEmpty) ...[
          const SizedBox(height: 6),
          Text(trFor(lang, 'offer_no_standing'),
              key: Key('offer_preview_${picked.factionId}'),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
        const SizedBox(height: 10),
        // One block under the ring (Wave 8): the clan's name and standing
        // on top (a tap on the name opens its charter), what this banner
        // gives on the left, the clan's radar on the right.
        Container(
          key: const Key('offer_clan_block'),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.6)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.26),
                color.withValues(alpha: 0.04),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      suitorName(picked, data, lang),
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: InkFonts.display, color: color),
                    ),
                  ),
                  // The same card a long press on the banner shows.
                  if (onRing)
                    IconButton(
                      key: const Key('offer_charter_open'),
                      tooltip: trFor(lang, 'clan_peek_orientation'),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(Icons.info_outline,
                          size: 20,
                          color: picked.firstMeeting
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant),
                      onPressed: () => showClanDetails(
                        context,
                        factionId: picked.factionId,
                        greeting: greeting,
                      ),
                    ),
                  if (tier != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      key: const Key('offer_standing_chip'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(tierColor(tier)).withValues(alpha: 0.15),
                        border: Border.all(
                            color:
                                Color(tierColor(tier)).withValues(alpha: 0.7)),
                      ),
                      child: Text(
                        trFor(lang, standingTierKey(tier)),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: Color(tierColor(tier)),
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      key: Key('offer_gift_block_${picked.factionId}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GiftIcon(gift: gift, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    giftName(gift,
                                        tables: tables,
                                        localizedItems: items,
                                        lang: lang),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 3),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      _Tag(
                                          text: trFor(
                                              lang, _giftTagKey(gift, skills)),
                                          color: color),
                                      if (gift.kind != GiftKind.perk)
                                        SignRarityChip(
                                            rarity: gift.rarity,
                                            language: lang),
                                      if (picked.risky)
                                        _Tag(
                                            key: const Key('offer_risky_badge'),
                                            text: trFor(
                                                lang, 'offer_risky_badge'),
                                            color: bad),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _GiftBody(
                          gift: gift,
                          tables: tables,
                          items: items,
                          skills: skills,
                          session: session,
                          lang: lang,
                        ),
                        // A risky gift (risky_gifts.dart): what the clan
                        // says, its price, and the odds.
                        if (picked.risky) ...[
                          const SizedBox(height: 6),
                          if ((faction?.riskyOfferFor(lang) ?? '').isNotEmpty)
                            Text(faction!.riskyOfferFor(lang),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontStyle: FontStyle.italic)),
                          Text(trFor(lang, 'offer_risky_hint'),
                              style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          RiskyOddsBar(
                              luck: ref
                                  .read(playerSessionProvider.notifier)
                                  .riskyLuck(tables)),
                          const SizedBox(height: 4),
                          Text(
                            riskyOddsText(
                                ref
                                    .read(playerSessionProvider.notifier)
                                    .riskyLuck(tables),
                                lang),
                            key: const Key('offer_risky_odds'),
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: bad, fontWeight: FontWeight.w700),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Container(
                          key: const Key('offer_alignment_word'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: alignColor.withValues(alpha: 0.7)),
                            color: alignColor.withValues(alpha: 0.10),
                          ),
                          child: Text(
                            '${trFor(lang, 'alignment_label')} · ${trFor(lang, alignKey)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: alignColor, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // What its gifts lean on (clanRadarProvider), on five axes.
                  if (onRing) ...[
                    const SizedBox(width: 6),
                    ClanRadarChart(
                        factionId: picked.factionId, color: color, size: 108),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The icon of a gift: an object's or a skill's own picture, else a mark
/// for its kind, on a square of the clan's colour.
class _GiftIcon extends StatelessWidget {
  const _GiftIcon({required this.gift, required this.color});

  final OfferGift gift;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('offer_gift_icon_${gift.id}'),
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: _giftGlyph(gift, color),
    );
  }
}

/// The picture inside a gift's tile: an object's or a skill's own, else a
/// mark for its kind.
Widget _giftGlyph(OfferGift gift, Color color) {
  final IconData fallback = switch (gift.kind) {
    GiftKind.skill => Icons.auto_fix_high,
    GiftKind.object => Icons.inventory_2_outlined,
    GiftKind.sign => Icons.auto_awesome,
    GiftKind.title => Icons.military_tech_outlined,
    GiftKind.sworn => Icons.gavel,
    GiftKind.spec => Icons.alt_route,
    GiftKind.perk => Icons.star_outline,
  };
  final mark = Icon(fallback, size: 24, color: color);
  return switch (gift.kind) {
    GiftKind.object =>
      PixelIcon(ItemIcons.pathFor(gift.id), size: 32, fallback: mark),
    GiftKind.skill =>
      PixelIcon(SkillIcons.pathFor(gift.id), size: 32, fallback: mark),
    _ => mark,
  };
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
  const _Tag({super.key, required this.text, required this.color});

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
      case GiftKind.spec:
        final fr = lang == AppLanguage.fr;
        final spec = tables.specs[gift.id];
        final variant = tables.specVariants[gift.id];
        final text = spec?.giftFor(fr) ?? variant?.textFor(fr);
        final voice = spec?.voiceFor(fr) ?? variant?.voiceFor(fr) ?? '';
        if (text == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A variant says which specialisation it bends.
            if (variant != null)
              Text(tables.specs[specId(variant.spec)]?.nameFor(fr) ?? '',
                  style: muted),
            lines([text]),
            if (voice.isNotEmpty)
              Text(voice, style: muted?.copyWith(fontStyle: FontStyle.italic)),
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
