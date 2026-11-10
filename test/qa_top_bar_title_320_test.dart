// QA guard for #892 (found by the 1.888.0 L3): at 320 x 568 the home top
// bar's title is shown whole on the Character, Camp and Other tabs, in both
// languages; before v1.893 the five buttons left it one or two letters
// ("C...", "Pe..."). Real fonts (the bundled ones).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart' show trFor;
import 'package:narrative_data_app/providers/home_tab_provider.dart';

import 'support/fonts.dart';
import 'support/open_game.dart';
import 'support/pump.dart';

/// Whether the AppBar's title text is laid out whole (no ellipsis, no cut).
bool _whole(WidgetTester tester, String title) {
  final finder = find.descendant(
      of: find.byType(AppBar), matching: find.textContaining(title));
  if (finder.evaluate().isEmpty) return false;
  final paragraph = tester.renderObject<RenderParagraph>(finder.first);
  final wanted = TextPainter(
      text: paragraph.text, textDirection: TextDirection.ltr, maxLines: 1)
    ..layout();
  return !paragraph.didExceedMaxLines &&
      paragraph.size.width >= wanted.width - 1;
}

void main() {
  testWidgets('320 x 568: the top bar shows the tab titles whole',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(320, 568));
    final container = await openGame(tester,
        session: {'raceId': 'human', 'professionId': 'warrior', 'level': 12});
    final failures = <String>[];
    for (final lang in [AppLanguage.en, AppLanguage.fr]) {
      await tester.runAsync(
          () => container.read(appLanguageProvider.notifier).setLanguage(lang));
      await settleApp(tester);
      for (final key in const ['nav_character', 'nav_camp', 'nav_other']) {
        await tester.tap(find.text(trFor(lang, key)).last);
        await settleApp(tester);
        final title = trFor(lang, key);
        if (!_whole(tester, title)) {
          failures.add('${lang.name} "$title" is cut in the top bar');
        }
      }
      container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
      await settleApp(tester);
    }
    expect(failures, isEmpty, reason: failures.join('; '));
  });
}
