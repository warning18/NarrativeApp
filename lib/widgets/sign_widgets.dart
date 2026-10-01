import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/signs.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../providers/signs_provider.dart';
import 'sign_offer_dialog.dart';

/// A patron's icon (patrons.json `icon`, see patronIconNames): a Material
/// icon, since patrons have no image of their own.
IconData patronIconFor(String name) => switch (name) {
      'flag' => Icons.flag,
      'brush' => Icons.brush,
      'palette' => Icons.palette,
      'landscape' => Icons.landscape,
      'terrain' => Icons.terrain,
      'hexagon' => Icons.hexagon,
      'local_fire_department' => Icons.local_fire_department,
      'whatshot' => Icons.whatshot,
      'water_drop' => Icons.water_drop,
      'menu_book' => Icons.menu_book,
      'history_edu' => Icons.history_edu,
      'auto_stories' => Icons.auto_stories,
      'edit' => Icons.edit,
      'fitness_center' => Icons.fitness_center,
      'hardware' => Icons.hardware,
      'waves' => Icons.waves,
      'sailing' => Icons.sailing,
      'anchor' => Icons.anchor,
      'eco' => Icons.eco,
      'spa' => Icons.spa,
      'park' => Icons.park,
      'local_florist' => Icons.local_florist,
      'wb_sunny' => Icons.wb_sunny,
      'light_mode' => Icons.light_mode,
      'brightness_7' => Icons.brightness_7,
      'dark_mode' => Icons.dark_mode,
      'nightlight' => Icons.nightlight,
      'bedtime' => Icons.bedtime,
      'dangerous' => Icons.dangerous,
      'shield' => Icons.shield,
      'bolt' => Icons.bolt,
      'star' => Icons.star,
      'auto_awesome' => Icons.auto_awesome,
      'pets' => Icons.pets,
      'visibility' => Icons.visibility,
      'diamond' => Icons.diamond,
      'church' => Icons.church,
      'castle' => Icons.castle,
      'music_note' => Icons.music_note,
      'notifications' => Icons.notifications,
      _ => Icons.draw_outlined,
    };

/// The color a rarity is shown in, readable on light and dark alike.
Color signRarityColor(SignRarity rarity) => switch (rarity) {
      SignRarity.common => const Color(0xFF8A8F98),
      SignRarity.rare => const Color(0xFF3A7BD5),
      SignRarity.epic => const Color(0xFF9B51E0),
      SignRarity.heroic => const Color(0xFFE08A1E),
    };

/// A patron's mark: their icon on a disc of their color. [dimmed] greys it
/// (a silent vow).
class PatronEmblem extends StatelessWidget {
  const PatronEmblem({
    super.key,
    required this.patron,
    this.size = 40,
    this.dimmed = false,
  });

  final Patron? patron;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final base = Color(patron?.color ?? 0xFFB08D3C);
    final color = dimmed ? Colors.grey : base;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.6)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.9), width: 1.5),
      ),
      child: Icon(patronIconFor(patron?.icon ?? ''),
          size: size * 0.55, color: Colors.white),
    );
  }
}

/// A rarity's word on a small pill of its color.
class SignRarityChip extends StatelessWidget {
  const SignRarityChip({
    super.key,
    required this.rarity,
    required this.language,
    this.level,
  });

  final SignRarity rarity;
  final AppLanguage language;

  /// The sign's level, shown after the rarity when given.
  final int? level;

  @override
  Widget build(BuildContext context) {
    final lang = language;
    final color = signRarityColor(rarity);
    final text = [
      trFor(lang, signRarityKey(rarity)),
      if (level != null) trFor(lang, 'sign_level').replaceAll('{n}', '$level'),
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

/// What a sign does at [rarity] and [level]: its effect lines, a pact's
/// curse in red (with [pactFightsLeft] when it is running), greyed when
/// [muted] (a silent vow, a pact still running).
class SignEffectText extends StatelessWidget {
  const SignEffectText({
    super.key,
    required this.sign,
    required this.rarity,
    required this.level,
    required this.language,
    this.pactFightsLeft,
    this.muted = false,
  });

  final SignDef sign;
  final SignRarity rarity;
  final int level;
  final AppLanguage language;
  final int? pactFightsLeft;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pact = sign.pact;
    final showPact = pact != null && (pactFightsLeft ?? pact.fights) > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in signEffectLines(sign, rarity, level, language))
          Text(
            line,
            style: theme.textTheme.bodySmall?.copyWith(
                color: muted ? theme.colorScheme.onSurfaceVariant : null),
          ),
        if (showPact)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              pactCurseText(pact, language, fights: pactFightsLeft),
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

/// The Character tab's Signs: the offer waiting, if any, Titan's Blood,
/// then the held signs by slot and the passives. A tap on a sign while
/// blood waits raises it.
class SignsSection extends ConsumerWidget {
  const SignsSection({super.key});

  Future<void> _raise(
      BuildContext context, WidgetRef ref, HeldSign held, SignDef sign) async {
    final lang = ref.read(appLanguageProvider);
    final name = sign.nameFor(lang);
    if (held.level >= maxSignLevel) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(trFor(lang, 'titan_blood_max').replaceAll('{name}', name))));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.water_drop, color: Color(0xFFB3261E)),
        title: Text(trFor(lang, 'titan_blood_confirm_title')
            .replaceAll('{name}', name)),
        content: Text(trFor(lang, 'titan_blood_confirm_body')
            .replaceAll('{n}', '${held.level + 1}')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(trFor(lang, 'cancel')),
          ),
          FilledButton(
            key: const Key('titan_blood_raise'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(trFor(lang, 'titan_blood_raise_button')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(playerSessionProvider.notifier).spendTitanBlood(held.signId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final signs = ref.watch(signDefsProvider);
    final patrons = ref.watch(patronsProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final held = [
      for (final h in session.heldSigns)
        if (signs[h.signId] != null) h,
    ];
    final canRaise = session.titanBlood > 0 && held.isNotEmpty;

    Widget tile(HeldSign h) {
      final sign = signs[h.signId]!;
      final silent = vowSilent(sign, session.alignmentScore);
      final muted = silent || h.pactPending;
      return InkWell(
        key: Key('sign_held_${h.signId}'),
        borderRadius: BorderRadius.circular(8),
        onTap: canRaise ? () => _raise(context, ref, h, sign) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PatronEmblem(
                  patron: patrons[sign.patronId], size: 32, dimmed: silent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          sign.nameFor(lang),
                          style: theme.textTheme.titleSmall?.copyWith(
                              color: silent
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null),
                        ),
                        SignRarityChip(
                            rarity: h.rarity, level: h.level, language: lang),
                      ],
                    ),
                    SignEffectText(
                      sign: sign,
                      rarity: h.rarity,
                      level: h.level,
                      language: lang,
                      pactFightsLeft: h.pactFightsLeft,
                      muted: muted,
                    ),
                    if (silent)
                      Text(
                        trFor(lang, 'sign_vow_silent'),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Text(
            text.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1),
          ),
        );

    final bySlot = <SignSlot, List<HeldSign>>{};
    for (final h in held) {
      bySlot.putIfAbsent(signs[h.signId]!.slot, () => []).add(h);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(tr(ref, 'signs_section'),
                  style: theme.textTheme.titleSmall),
            ),
            if (session.titanBlood > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.water_drop,
                      size: 16, color: Color(0xFFB3261E)),
                  const SizedBox(width: 2),
                  Text(
                    tr(ref, 'titan_blood_label')
                        .replaceAll('{n}', '${session.titanBlood}'),
                    key: const Key('titan_blood_count'),
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
          ],
        ),
        if (session.titanBlood > 0)
          Text(
            tr(ref, held.isEmpty ? 'titan_blood_no_sign' : 'titan_blood_hint'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        if (session.pendingSignPicks > 0) ...[
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            key: const Key('sign_open_offer'),
            icon: const Icon(Icons.draw_outlined),
            onPressed: () =>
                showSignOfferIfWaiting(context, ref, sayWhenNone: true),
            label: Text(
              '${tr(ref, 'sign_open_offer_button')} · '
              '${tr(ref, 'sign_pending').replaceAll('{n}', '${session.pendingSignPicks}')}',
            ),
          ),
        ],
        const SizedBox(height: 4),
        if (held.isEmpty)
          Text(tr(ref, 'signs_none'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        for (final slot in [
          SignSlot.strike,
          SignSlot.guard,
          SignSlot.mend,
          SignSlot.spell,
        ])
          if (bySlot[slot] != null) ...[
            label(tr(ref, signSlotKey(slot))),
            for (final h in bySlot[slot]!) tile(h),
          ],
        if (bySlot[SignSlot.passive] != null) ...[
          label(tr(ref, 'sign_passives_label')),
          for (final h in bySlot[SignSlot.passive]!) tile(h),
        ],
      ],
    );
  }
}

/// The codex's Patrons: those met so far (see PlayerSession.patronsMet)
/// with their favour, and whether this life has closed them off.
class PatronsCodex extends ConsumerWidget {
  const PatronsCodex({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final patrons = ref.watch(patronsProvider);
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final met = [
      for (final id in session.patronsMet)
        if (patrons[id] != null) patrons[id]!,
    ]..sort((a, b) => a.kind.index != b.kind.index
        ? a.kind.index.compareTo(b.kind.index)
        : a.nameFor(lang).compareTo(b.nameFor(lang)));
    if (met.isEmpty) {
      return Text(tr(ref, 'patrons_none_met'),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final patron in met)
          Padding(
            key: Key('patron_codex_${patron.id}'),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PatronEmblem(patron: patron, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patron.nameFor(lang),
                          style: theme.textTheme.titleSmall),
                      Text(
                        '${tr(ref, 'patron_kind_${patron.kind.name}')} · '
                        '${tr(ref, 'patron_favour').replaceAll('{n}', '${session.patronFavour[patron.id] ?? 0}').replaceAll('{l}', '${favourLevelFor(session.patronFavour[patron.id] ?? 0)}')}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      if (patron.introFor(lang).isNotEmpty)
                        Text(
                          patron.introFor(lang),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      if (closedThisLife(patron,
                          patronsThisLife: session.signPatronsThisLife,
                          patrons: patrons))
                        Text(
                          tr(ref, 'patron_closed_life'),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
