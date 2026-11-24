// The fate coin offered on a roll that went wrong (fate_coin.dart): the
// camp fate's failed check and a Flawed forge roll ask with this dialog;
// the land crossing asks under its own die.
import 'package:flutter/material.dart';

import '../data/fate_coin.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';

/// Asks whether to flip the fate coin, with [messageKey]'s words: true
/// when the player flips it.
Future<bool> offerFateCoin(
  BuildContext context,
  AppLanguage language, {
  String messageKey = 'fate_coin_offer',
}) async {
  String t(String key) => trFor(language, key);
  final flip = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('fate_coin_offer'),
      content: Text(t(messageKey)),
      actions: [
        TextButton(
          key: const Key('fate_coin_keep'),
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(t('fate_coin_keep_button')),
        ),
        FilledButton(
          key: const Key('fate_coin_flip'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(t('fate_coin_flip_button')),
        ),
      ],
    ),
  );
  return flip ?? false;
}

/// "The coin lands heads, and is spent." in [language].
String fateCoinLandedLine(FateCoinFace face, AppLanguage language) =>
    trFor(language, 'fate_coin_landed')
        .replaceAll('{face}', trFor(language, 'fate_coin_${face.name}'));
