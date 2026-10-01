import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart';
import '../data/signs.dart';
import '../data/throne.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/player_session_provider.dart';
import 'clan_widgets.dart';
import 'sign_widgets.dart';

/// The climb to the Lantern Throne and the Host (v1.196, see throne.dart),
/// on screen: the Character tab's climb ([ClimbCard]), its rungs
/// ([ClimbRungs], Edit Mode's Throne tab shows them too) and "Your Host"
/// ([showHostSheet]).

/// A faction's emblem: a lost clan's (the Open Hand) as its remembrance
/// allows, any other's its own.
Widget _emblem(Faction? faction, Iterable<String> flags, {double size = 24}) {
  if (faction == null) return SizedBox(width: size, height: size);
  return faction.isLost
      ? LostClanEmblem(
          faction: faction, stage: openHandStageFrom(flags), size: size)
      : PatronEmblem(patron: faction.patron, size: size);
}

/// One rung of the climb as a small chip: reached (a tick, the tier's
/// gold) or not yet (an empty ring). Never wider than the row it is in.
class _RungChip extends StatelessWidget {
  const _RungChip({
    super.key,
    required this.label,
    required this.reached,
    required this.language,
  });

  final String label;
  final bool reached;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = reached
        ? standingTierTextColor(context, StandingTier.sworn)
        : theme.colorScheme.onSurfaceVariant;
    return LayoutBuilder(builder: (context, constraints) {
      return Semantics(
        label: trFor(
                language, reached ? 'throne_rung_reached' : 'throne_rung_open')
            .replaceAll('{rung}', label),
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: reached ? colour : theme.colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(reached ? Icons.check_circle : Icons.circle_outlined,
                    size: 14, color: colour),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: colour,
                        fontWeight: reached ? FontWeight.w700 : null),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// [climb]'s three rungs: House (with the House found), Clan (its steps
/// done, n/3; the lost clan has none) and Throne.
class ClimbRungs extends StatelessWidget {
  const ClimbRungs({
    super.key,
    required this.climb,
    required this.data,
    required this.language,
  });

  final Climb climb;
  final ClanData data;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final house = climb.house;
    final lost = data.faction(climb.factionId)?.isLost ?? false;
    final houseLabel = trFor(language, 'throne_rung_house');
    return Wrap(
      key: Key('climb_rungs_${climb.factionId}'),
      spacing: 6,
      runSpacing: 4,
      children: [
        _RungChip(
          key: Key('climb_rung_house_${climb.factionId}'),
          label: house == null
              ? houseLabel
              : '$houseLabel · ${house.nameFor(language)}',
          reached: climb.hasHouse,
          language: language,
        ),
        _RungChip(
          key: Key('climb_rung_clan_${climb.factionId}'),
          label: lost
              ? trFor(language, 'throne_rung_clan_plain')
              : trFor(language, 'throne_rung_clan')
                  .replaceAll('{n}', '${climb.claimed ? 3 : climb.steps}'),
          reached: climb.claimed || climb.crowned,
          language: language,
        ),
        _RungChip(
          key: Key('climb_rung_throne_${climb.factionId}'),
          label: trFor(language, 'throne_rung_throne'),
          reached: climb.crowned,
          language: language,
        ),
      ],
    );
  }
}

/// The Character tab's climb (in the Clans section): the claim, or the
/// faction furthest up; its rungs; once crowned, the Throne; once
/// mustered, "Your Host". Nothing while no climb has begun.
class ClimbCard extends ConsumerWidget {
  const ClimbCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(clanDataProvider);
    final politics = ref.watch(politicsProvider);
    final flags = ref.watch(playerSessionProvider.select((s) => s.flags));
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final focus = climbFocusFor(politics, flags, data);
    if (focus.isEmpty && politics.claim.isEmpty && !politics.host.mustered) {
      return const SizedBox.shrink();
    }
    final faction = data.faction(focus);
    final name = throneFactionName(focus, data, lang);
    final crowned = politics.throneWinner.isNotEmpty;
    final claimed = politics.claim.isNotEmpty;
    final headline = crowned
        ? trFor(lang, 'throne_on_throne').replaceAll('{name}', name)
        : claimed
            ? trFor(lang, 'throne_your_claim').replaceAll('{name}', name)
            : trFor(lang, 'throne_climbing').replaceAll('{name}', name);
    return Card(
      key: const Key('character_climb'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: crowned
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: standingTierColor(StandingTier.sworn), width: 1.5))
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(crowned ? Icons.workspace_premium : Icons.stairs_outlined,
                    size: 18,
                    color: crowned
                        ? standingTierColor(StandingTier.sworn)
                        : theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(trFor(lang, 'throne_climb_title'),
                      style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            Text(trFor(lang, 'throne_climb_hint'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            if (!claimed && !crowned)
              Text(trFor(lang, 'throne_no_claim'),
                  key: const Key('climb_no_claim'),
                  style: theme.textTheme.bodyMedium),
            if (focus.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _emblem(faction, flags),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      headline,
                      key: const Key('climb_headline'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: claimed || crowned
                              ? FontWeight.w700
                              : FontWeight.normal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClimbRungs(
                climb: climbFor(focus, politics, flags, data),
                data: data,
                language: lang,
              ),
            ],
            if (politics.host.mustered)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('climb_open_host'),
                  icon: const Icon(Icons.groups_2_outlined, size: 18),
                  label: Text(trFor(lang, 'host_title')),
                  onPressed: () => showHostSheet(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Opens "Your Host": the one mustered, or, with [preview] (Edit Mode),
/// the one the character would muster now.
Future<void> showHostSheet(BuildContext context, {bool preview = false}) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(child: HostSheet(preview: preview)),
    );

/// "Your Host" (see [showHostSheet]): the Banner, the allies and the
/// Houses, each with what they bring.
class HostSheet extends ConsumerWidget {
  const HostSheet({super.key, this.preview = false});

  final bool preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(clanDataProvider);
    final session = ref.watch(playerSessionProvider);
    final politics = session.politics;
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final host = preview || !politics.host.mustered
        ? hostFor(
            politics: politics,
            data: data,
            signPatrons: session.signPatronsThisLife)
        : politics.host;
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    Widget section(String text) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(text.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1)),
        );
    String why(String id) {
      final faction = data.faction(id);
      if (politics.hasPledged(id)) return trFor(lang, 'host_why_pledged');
      if (faction?.kind == PatronKind.otherworld) {
        return trFor(lang, 'host_why_sign');
      }
      return trFor(lang, standingTierKey(politics.tierOf(id, data)));
    }

    Widget contingent(String id, {String? note}) {
      final faction = data.faction(id);
      final contingent = faction?.host;
      return Padding(
        key: Key('host_contingent_$id'),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _emblem(faction, session.flags, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(throneFactionName(id, data, lang),
                      style: theme.textTheme.titleSmall),
                  if (note != null) Text(note, style: muted),
                  if ((contingent?.lineFor(lang) ?? '').isNotEmpty)
                    Text(contingent!.lineFor(lang),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontStyle: FontStyle.italic)),
                  for (final effect in contingent?.effects ?? const [])
                    Text(signEffectText(effect, lang),
                        style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      key: const Key('host_sheet'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.groups_2_outlined,
                  color: standingTierColor(StandingTier.sworn)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(trFor(lang, 'host_title'),
                    style: theme.textTheme.titleMedium),
              ),
              Text(
                trFor(lang, 'host_size').replaceAll('{n}', '${host.size}'),
                key: const Key('host_size'),
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(trFor(lang, host.mustered ? 'host_intro' : 'host_preview_intro'),
              style: muted),
          if (host.mustered)
            Text(
              trFor(lang, 'host_mustered_on')
                  .replaceAll('{c}', '${host.chapter}')
                  .replaceAll('{d}', '${host.day}'),
              style: theme.textTheme.labelSmall,
            ),
          section(trFor(lang, 'host_banner')),
          if (host.banner.isEmpty)
            Text(trFor(lang, 'host_no_banner'), style: muted)
          else
            contingent(host.banner),
          section(trFor(lang, 'host_allies')),
          if (host.allies.isEmpty)
            Text(trFor(lang, 'host_no_allies'), style: muted)
          else
            for (final id in host.allies) contingent(id, note: why(id)),
          section(trFor(lang, 'host_houses')),
          if (host.houses.isEmpty)
            Text(trFor(lang, 'host_no_houses'), style: muted)
          else ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final id in host.houses)
                  Chip(
                    key: Key('host_house_$id'),
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(Icons.shield_outlined,
                        size: 16,
                        color: Color(data.subclan(id)?.color ?? 0xFFB08D3C)),
                    label: Text(data.subclan(id)?.nameFor(lang) ?? id,
                        style: theme.textTheme.labelSmall),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(trFor(lang, 'host_houses_line'),
                style: theme.textTheme.bodySmall),
            for (final effect in houseEffects(host.houses.length))
              Text(signEffectText(effect, lang),
                  style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
