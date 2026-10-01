import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/signs.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/signs_provider.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import 'sign_widgets.dart';

/// Opens the sign offer when a pick waits (see signs.dart), as the perk
/// choice opens in the level-up dialog: after an odd level's dialog, after
/// a boss, from the Character tab. The offer is drawn once and kept, so
/// closing the dialog ("Later") never loses or redraws it. [sayWhenNone]:
/// when no patron has anything to offer, say so (the Character tab's
/// button) rather than nothing (after a fight).
Future<void> showSignOfferIfWaiting(BuildContext context, WidgetRef ref,
    {bool sayWhenNone = false}) async {
  if (ref.read(playerSessionProvider).pendingSignPicks <= 0) return;
  final patrons = parsePatrons(
      await ref.read(gameDbProvider(patronsSchema).notifier).whenLoaded());
  final signs = parseSigns(
      await ref.read(gameDbProvider(signsSchema).notifier).whenLoaded());
  final offer = await ref
      .read(playerSessionProvider.notifier)
      .ensureSignOffer(patrons: patrons, signs: signs);
  if (!context.mounted) return;
  if (offer == null) {
    if (sayWhenNone) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr(ref, 'sign_none_to_offer'))));
    }
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (_) => const SignOfferDialog(),
  );
}

/// The offer on the table: the patron (their color, their mark, their
/// greeting, or their intro the first time), then the cards, each with its
/// rarity, slot, what it does in numbers, its flavour, what it would
/// replace, a duo's badge and a pact's price in red. A tap picks a card,
/// "Take this sign" confirms it; the next offer follows while picks remain.
class SignOfferDialog extends ConsumerStatefulWidget {
  const SignOfferDialog({super.key});

  @override
  ConsumerState<SignOfferDialog> createState() => _SignOfferDialogState();
}

class _SignOfferDialogState extends ConsumerState<SignOfferDialog> {
  String? _selected;
  bool _busy = false;

  Future<void> _take(
      Map<String, Patron> patrons, Map<String, SignDef> signs) async {
    final signId = _selected;
    if (signId == null || _busy) return;
    setState(() => _busy = true);
    final notifier = ref.read(playerSessionProvider.notifier);
    await notifier.chooseSign(signId, signs: signs);
    final next = await notifier.ensureSignOffer(patrons: patrons, signs: signs);
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
    final patrons = ref.watch(patronsProvider);
    final signs = ref.watch(signDefsProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final offer = session.signOffer;
    final patron = offer == null ? null : patrons[offer.patronId];
    if (offer == null || patron == null) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(heightFactor: 1, child: CircularProgressIndicator()),
        ),
      );
    }
    final color = Color(patron.color);
    final greeting = offer.firstMeeting && patron.introFor(lang).isNotEmpty
        ? patron.introFor(lang)
        : patron.greetingFor(lang, offer.greetingIndex);

    final header = TutorialTarget(
      id: 'signs.patron',
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.08),
            ],
          ),
          border:
              Border(bottom: BorderSide(color: color.withValues(alpha: 0.6))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PatronEmblem(patron: patron, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patron.nameFor(lang),
                    key: const Key('sign_offer_patron'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (greeting.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
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
    );

    final cards = TutorialTarget(
      id: 'signs.cards',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final card in offer.cards)
            if (signs[card.signId] case final sign?)
              _OfferCard(
                key: Key('sign_offer_${card.signId}'),
                sign: sign,
                rarity: card.rarity,
                // A sign for a filled slot keeps the old one's level.
                level:
                    heldInSlot(sign.slot, session.heldSigns, signs)?.level ?? 1,
                replaces: heldInSlot(sign.slot, session.heldSigns, signs),
                signs: signs,
                language: lang,
                accent: color,
                selected: _selected == card.signId,
                onTap: _busy
                    ? null
                    : () => setState(() => _selected = card.signId),
              ),
        ],
      ),
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: TutorialTrigger(
        topic: TutorialTopic.signs,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      session.pendingSignPicks > 1
                          ? '${tr(ref, 'sign_choose_hint')} · '
                              '${tr(ref, 'sign_pending').replaceAll('{n}', '${session.pendingSignPicks}')}'
                          : tr(ref, 'sign_choose_hint'),
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    cards,
                  ],
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
                    child: Text(tr(ref, 'sign_later_button')),
                  ),
                  FilledButton(
                    key: const Key('sign_take_button'),
                    style: FilledButton.styleFrom(backgroundColor: color),
                    onPressed: _selected == null || _busy
                        ? null
                        : () => _take(patrons, signs),
                    child: Text(tr(ref, 'sign_take_button')),
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

/// One card of the offer.
class _OfferCard extends StatelessWidget {
  const _OfferCard({
    super.key,
    required this.sign,
    required this.rarity,
    required this.level,
    required this.replaces,
    required this.signs,
    required this.language,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final SignDef sign;
  final SignRarity rarity;
  final int level;
  final HeldSign? replaces;
  final Map<String, SignDef> signs;
  final AppLanguage language;
  final Color accent;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final replaced = replaces == null ? null : signs[replaces!.signId];
    // Taken over a filled slot, the better of the two rarities stays.
    final shownRarity =
        replaces != null && replaces!.rarity.index > rarity.index
            ? replaces!.rarity
            : rarity;
    Widget tag(String text, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Text(text,
              style: theme.textTheme.labelSmall?.copyWith(color: color)),
        );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? accent : theme.colorScheme.outlineVariant,
          width: selected ? 2.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      sign.nameFor(language),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SignRarityChip(
                      rarity: shownRarity,
                      level: level > 1 ? level : null,
                      language: language),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  tag(trFor(language, signSlotKey(sign.slot)),
                      theme.colorScheme.onSurfaceVariant),
                  if (sign.isDuo)
                    tag(trFor(language, 'sign_duo_badge'), accent),
                ],
              ),
              const SizedBox(height: 6),
              SignEffectText(
                sign: sign,
                rarity: shownRarity,
                level: level,
                language: language,
              ),
              if (replaced != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    trFor(language, 'sign_replaces')
                        .replaceAll('{name}', replaced.nameFor(language)),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              if (sign.flavourFor(language).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    sign.flavourFor(language),
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
