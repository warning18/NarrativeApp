// The choice after a rival's hunter is beaten (hunter_mercy.dart): spare
// them or finish it. The hunter's own portrait over a band in its clan's
// colour, the words, what a high Perception reads of them as a chip in the
// colour of their side, and two options that say what each costs and gives.
import 'package:flutter/material.dart';

import '../data/factions.dart';
import '../data/hunter_mercy.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';
import '../utils/pixel_icons/enemy_icons.dart';
import '../utils/pixel_icons/pixel_icon.dart';

/// Asks whether to spare [name] ([enemyId]) of [clan]; true to spare, false
/// to finish it. [read] is what the party's Perception reads of them, when
/// it is high enough.
Future<bool> showMercyDialog(
  BuildContext context, {
  required String enemyId,
  required String name,
  required Faction? clan,
  required AppLanguage lang,
  ({String side, bool close})? read,
}) async {
  final spared = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => MercyDialog(
      enemyId: enemyId,
      name: name,
      clan: clan,
      lang: lang,
      read: read,
      onChoose: (spare) => Navigator.pop(dialogContext, spare),
    ),
  );
  return spared ?? false;
}

class MercyDialog extends StatelessWidget {
  const MercyDialog({
    super.key,
    required this.enemyId,
    required this.name,
    required this.clan,
    required this.lang,
    required this.read,
    required this.onChoose,
  });

  final String enemyId;
  final String name;
  final Faction? clan;
  final AppLanguage lang;
  final ({String side, bool close})? read;
  final ValueChanged<bool> onChoose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final colour = clan == null ? ink.ash : Color(clan!.color | 0xFF000000);
    final clanName = clan?.shortFor(lang) ?? '';
    String t(String key) => trFor(lang, key);
    final readColour = switch (read?.side) {
      'good' => ink.heal,
      'evil' => ink.blood,
      _ => ink.ash,
    };
    return PopScope(
      canPop: false,
      child: Dialog(
        key: const Key('mercy_dialog'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colour.withValues(alpha: 0.32),
                      colour.withValues(alpha: 0.06),
                    ],
                  ),
                  border: Border(
                      bottom: BorderSide(color: colour.withValues(alpha: 0.8))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black.withValues(alpha: 0.35),
                        border: Border.all(color: colour, width: 2),
                      ),
                      child: PixelIcon(
                        EnemyIcons.pathFor(enemyId),
                        size: 72,
                        fallback: Icon(Icons.person, size: 40, color: colour),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (clanName.isNotEmpty)
                            Text(clanName.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        Color.lerp(colour, Colors.white, 0.4),
                                    fontFamily: InkFonts.system,
                                    letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text(
                            t('mercy_title').replaceAll('{name}', name),
                            key: const Key('mercy_title'),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontFamily: InkFonts.display),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(t('mercy_body'), style: theme.textTheme.bodyMedium),
              ),
              if (read != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                  child: Container(
                    key: Key('mercy_read_${read!.side}'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: readColour.withValues(alpha: 0.12),
                      border:
                          Border.all(color: readColour.withValues(alpha: 0.7)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 18, color: readColour),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t('mercy_read_${read!.side}') +
                                t(read!.close
                                    ? 'mercy_read_close'
                                    : 'mercy_read_far'),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      key: const Key('mercy_spare'),
                      style: FilledButton.styleFrom(
                          backgroundColor: ink.heal,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10)),
                      onPressed: () => onChoose(true),
                      child: _option(
                          theme,
                          t('mercy_spare_button'),
                          t('mercy_spare_sub')
                              .replaceAll('{clan}', clanName)
                              .replaceAll('{n}', '+$spareStanding'),
                          Colors.black),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const Key('mercy_finish'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: ink.blood,
                          side: BorderSide(color: ink.blood),
                          padding: const EdgeInsets.symmetric(vertical: 10)),
                      onPressed: () => onChoose(false),
                      child: _option(
                          theme,
                          t('mercy_finish_button'),
                          t('mercy_finish_sub')
                              .replaceAll('{clan}', clanName)
                              .replaceAll('{n}', '\u2212${-finishStanding}'),
                          ink.blood),
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

  Widget _option(ThemeData theme, String title, String sub, Color colour) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700, color: colour)),
          Text(sub,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: colour.withValues(alpha: 0.85))),
        ],
      );
}
