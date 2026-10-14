// The Clans screen's compass (Wave 7 D): the six clans on their ring, each
// crest wearing where the character stands with it, and a tap on a crest
// drawing its lines to the others, with its friends and foes named under.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/clans_provider.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import 'clan_compass.dart';

class ClanCompassCard extends ConsumerStatefulWidget {
  const ClanCompassCard({super.key});

  @override
  ConsumerState<ClanCompassCard> createState() => _ClanCompassCardState();
}

class _ClanCompassCardState extends ConsumerState<ClanCompassCard> {
  String? _focus;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(clanDataProvider);
    final politics = ref.watch(playerSessionProvider.select((s) => s.politics));
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    if (data.clans.length < 3) return const SizedBox.shrink();
    int? stepOf(String a, String b) => politics.relationStep(a, b, data);
    String names(Iterable<String> ids) =>
        ids.map((id) => data.faction(id)?.shortFor(lang) ?? id).join(' · ');
    final focus = _focus == null ? null : data.faction(_focus!);
    final friends = focus == null
        ? const <String>[]
        : alliesOf(focus.patron.id, politics, data);
    final foes = focus == null
        ? const <String>[]
        : rivalsOf(focus.patron.id, politics, data);
    return Container(
      key: const Key('clans_compass_card'),
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ink.seam),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr(ref, 'clans_compass_title'),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontFamily: InkFonts.display, color: ink.gold)),
          const SizedBox(height: 2),
          Text(tr(ref, 'clans_compass_hint'),
              style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
          const SizedBox(height: 8),
          ClanCompass(
            clans: data.clans,
            language: lang,
            relations: data.relations,
            stepOf: stepOf,
            focusId: _focus,
            height: 214,
            badges: {
              for (final c in data.clans)
                c.patron.id: (
                  text: '${politics.standingOf(c.patron.id, data).round()}',
                  color: Color(tierColor(politics.tierOf(c.patron.id, data)) |
                      0xFF000000),
                ),
            },
            onTap: (id) => setState(() => _focus = _focus == id ? null : id),
          ),
          if (focus != null) ...[
            const SizedBox(height: 8),
            Text(focus.nameFor(lang),
                key: const Key('clans_compass_focus'),
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: Color(focus.color | 0xFF000000))),
            Text(
                trFor(lang,
                    standingTierKey(politics.tierOf(focus.patron.id, data))),
                style: theme.textTheme.labelSmall?.copyWith(
                    color: Color(
                        tierColor(politics.tierOf(focus.patron.id, data)) |
                            0xFF000000))),
            if (friends.isNotEmpty)
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: '${tr(ref, 'clans_compass_friends')} · ',
                      style: TextStyle(color: ink.heal)),
                  TextSpan(text: names(friends)),
                ]),
                style: theme.textTheme.bodySmall,
              ),
            if (foes.isNotEmpty)
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: '${tr(ref, 'clans_compass_foes')} · ',
                      style: TextStyle(color: ink.blood)),
                  TextSpan(text: names(foes)),
                ]),
                style: theme.textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }
}
