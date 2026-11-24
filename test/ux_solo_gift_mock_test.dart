// The one-card clan offer (Core's proposal 3), pictures only (UX_SHOTS=<folder>):
// when an offer would hold a specialisation or a Sworn boon, that gift comes
// alone. The clan's banner and the suitor's greeting as today, the gift at
// full width, "Accept" (main) and "Not now" (quiet), and one line saying the
// gift may come again. A specialisation and a Sworn boon, English and French,
// 360 and 320 wide, in today's style (the story game, not the ink look). The
// words of the two buttons and the line are the Manager's; Narrative will word
// the rest. Mock only.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/signs.dart' show SignRarity;
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';
import 'package:narrative_data_app/widgets/sign_widgets.dart';

import 'support/fonts.dart';

const _clan = Color(0xFF2F62B5); // the Lantern Dominion

class _Gift {
  const _Gift(this.name, this.tagKey, this.text, this.icon);
  final String name;
  final String tagKey;
  final String text;
  final IconData icon;
}

Widget _tag(BuildContext context, String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );

Widget _sheet(BuildContext context, AppLanguage lang, _Gift gift,
    String greeting, String clanName) {
  final theme = Theme.of(context);
  final w = MediaQuery.sizeOf(context).width;
  const accept = {AppLanguage.en: 'Accept', AppLanguage.fr: 'Accepter'};
  const later = {AppLanguage.en: 'Not now', AppLanguage.fr: 'Plus tard'};
  const line = {
    AppLanguage.en: 'Not now is not never. The gift may come again later.',
    AppLanguage.fr:
        'Pas maintenant n’est pas jamais. Le don peut revenir plus tard.',
  };
  return Material(
    color: theme.colorScheme.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: w - 24,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The header, as the offer's today.
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Row(children: [
                Icon(Icons.diversity_3, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(trFor(lang, 'offer_title'),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(trFor(lang, 'offer_source_level'),
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ])),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The clan: its banner, its name and standing, what it says.
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _clan.withValues(alpha: 0.6)),
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _clan.withValues(alpha: 0.26),
                              _clan.withValues(alpha: 0.04)
                            ]),
                      ),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PixelBanner(id: 'clan_dominion', scale: 1),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(clanName,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontFamily: InkFonts.display,
                                              color: _clan)),
                                  const SizedBox(height: 4),
                                  _tag(
                                      context,
                                      trFor(lang, 'standing_tier_friend'),
                                      _clan),
                                  const SizedBox(height: 8),
                                  Text('“$greeting”',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              fontFamily: InkFonts.prose,
                                              fontStyle: FontStyle.italic,
                                              height: 1.35)),
                                ])),
                          ]),
                    ),
                    const SizedBox(height: 10),
                    // The gift, alone, at full width.
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _clan, width: 2),
                        color: theme.colorScheme.surfaceContainerLow,
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                    color: _clan.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: _clan.withValues(alpha: 0.7))),
                                child: Icon(gift.icon, color: _clan, size: 26),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(gift.name,
                                        style: theme.textTheme.titleMedium),
                                    const SizedBox(height: 4),
                                    Wrap(spacing: 6, runSpacing: 4, children: [
                                      _tag(context, trFor(lang, gift.tagKey),
                                          _clan),
                                      SignRarityChip(
                                          rarity: SignRarity.epic,
                                          language: lang),
                                    ]),
                                  ])),
                            ]),
                            const SizedBox(height: 10),
                            Text(gift.text,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(height: 1.4)),
                          ]),
                    ),
                  ]),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: _clan,
                            minimumSize: const Size.fromHeight(48)),
                        onPressed: () {},
                        child: Text(accept[lang]!)),
                    const SizedBox(height: 4),
                    TextButton(
                        style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(44)),
                        onPressed: () {},
                        child: Text(later[lang]!)),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(line[lang]!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic)),
                    ),
                  ]),
            ),
          ]),
    ),
  );
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  testWidgets('the one-card clan offer', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    final fac =
        jsonDecode(File('assets/gamedata/factions.json').readAsStringSync())
            as Map<String, dynamic>;
    final spec = (jsonDecode(
            File('assets/gamedata/specialisations.json').readAsStringSync())
        as Map<String, dynamic>)['lantern_vanguard'] as Map<String, dynamic>;
    final dom = fac['dominion'] as Map<String, dynamic>;
    final sworn = dom['sworn'] as Map<String, dynamic>;
    String pick(Map<String, dynamic> m, String k, AppLanguage l) =>
        (l == AppLanguage.fr ? m['${k}_fr'] : m[k]) as String;
    List<String> greetings(AppLanguage l) {
      final raw =
          (l == AppLanguage.fr ? dom['greetings_fr'] : dom['greetings']);
      return raw is List ? [for (final g in raw) '$g'] : [raw.toString()];
    }

    for (final width in [360.0, 320.0]) {
      for (final lang in [AppLanguage.en, AppLanguage.fr]) {
        for (final kind in ['spec', 'boon']) {
          final gift = kind == 'spec'
              ? _Gift(pick(spec, 'name', lang), 'offer_gift_spec',
                  pick(spec, 'gift', lang), Icons.auto_awesome)
              : _Gift(pick(sworn, 'name', lang), 'offer_gift_sworn',
                  pick(sworn, 'text', lang), Icons.local_fire_department);
          final key = GlobalKey();
          tester.view.physicalSize = Size(width, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(
                  AppPalette.stitchedInk.schemeFor(Brightness.light)),
              home: Builder(
                  builder: (context) => Scaffold(
                      backgroundColor: Colors.black54,
                      body: Center(
                          child: SingleChildScrollView(
                              child: _sheet(
                                  context,
                                  lang,
                                  gift,
                                  greetings(lang)[kind == 'spec' ? 0 : 1],
                                  pick(dom, 'name', lang)))))),
            ),
          ));
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 250)));
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull,
              reason: '$width ${lang.name} $kind');
          await tester.runAsync(() async {
            final render =
                key.currentContext!.findRenderObject() as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            File('$shots/solo-$kind-${lang.name}-${width.toInt()}.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          });
          await tester.pumpWidget(const SizedBox());
        }
      }
    }
  });
}
