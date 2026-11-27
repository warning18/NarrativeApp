// PICTURES (UX_SHOTS=<folder>): MOCKS of the oath as its own Yes/No moment
// after the loot, never a card: A, a banner sheet over the floor; B, a
// full-width moment with the clan's banner. Real: the floor's plate, the
// clan's banner and disc, its die. Not wired in.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/tower_backdrop.dart';
import 'package:narrative_data_app/screens/tower/tower_offer_view.dart'
    show towerDieName;
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/die_tile.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';

import 'support/fonts.dart';

TextStyle _p(double s, Color c, {FontWeight? w}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.25,
    color: c,
    fontWeight: w);
TextStyle _d(double s, Color c) =>
    TextStyle(fontFamily: InkFonts.display, fontSize: s, height: 1.1, color: c);

Widget _pips(int now, int gain, int max) =>
    Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < max; i++)
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
              color: i < now
                  ? inkPaper
                  : i < now + gain
                      ? inkGold
                      : Colors.transparent,
              border: Border.all(color: i < now + gain ? inkPaper : inkGrey),
              borderRadius: BorderRadius.circular(2)),
        ),
    ]);

Widget _buttons(String clan) =>
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: inkRed,
              foregroundColor: inkPaper,
              minimumSize: const Size.fromHeight(48)),
          onPressed: () {},
          child: const Text('Swear')),
      TextButton(
          onPressed: () {},
          child: Text('Not now (+1 mark)',
              style: _p(14, inkGold, w: FontWeight.w700))),
    ]);

class _Gains extends StatelessWidget {
  const _Gains(
      {required this.dieId, required this.dieName, required this.faces});
  final String dieId, dieName;
  final int faces;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                border: Border.all(color: inkSlate),
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              DieTile(dieId: dieId, faces: faces, size: 44),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Their die', style: _p(10, inkGrey)),
                      Text(dieName, style: _d(14, inkPaper)),
                    ]),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                border: Border.all(color: inkSlate),
                borderRadius: BorderRadius.circular(8)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Standing', style: _p(10, inkGrey)),
              Text('+2 with them', style: _d(14, inkPaper)),
              const SizedBox(height: 4),
              _pips(4, 2, 6),
            ]),
          ),
        ),
      ]);
}

class _Oath extends ConsumerWidget {
  const _Oath(this.version);
  final String version;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final f = ref.watch(factionsProvider)['mire'];
    if (f == null) return const SizedBox.shrink();
    final clan = f.shortFor(lang);
    final data = towerDataFromAssets();
    final dieId = towerClanDieOf('mire', data.dice)!;
    final dieName = towerDieName(ref, dieId);
    final faces = (data.dice[dieId] as Map)['numberOfFaces'] as int;
    final colour = Color(f.color | 0xFF000000);
    final lore = tr(ref, 'tower_oath_line_mire');
    if (version == 'A') {
      return TowerBackdrop(
        floor: 6,
        child: Stack(children: [
          Positioned.fill(
              child: ColoredBox(color: inkBlack.withValues(alpha: 0.55))),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              decoration: BoxDecoration(
                  color: inkBlack,
                  border: Border.all(color: colour, width: 2),
                  borderRadius: BorderRadius.circular(10)),
              child: Stack(clipBehavior: Clip.none, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 96),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Swear to the $clan?',
                                    style: _d(22, inkPaper)),
                                const SizedBox(height: 6),
                                Text(lore, style: _p(12.5, inkGrey)),
                                const SizedBox(height: 28),
                              ]),
                        ),
                        _Gains(dieId: dieId, dieName: dieName, faces: faces),
                        const SizedBox(height: 10),
                        _buttons(clan),
                      ]),
                ),
                // The banner hangs from the sheet's top edge.
                Positioned(
                    top: -78,
                    left: 14,
                    child: SizedBox(
                        width: 72,
                        height: 144,
                        child: FittedBox(
                            fit: BoxFit.fill,
                            child: PixelBanner(
                                id: clanBannerId('mire')!, scale: 1)))),
              ]),
            ),
          ),
        ]),
      );
    }
    return TowerBackdrop(
      floor: 6,
      child: Stack(children: [
        Positioned.fill(
            child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
              colour.withValues(alpha: 0.55),
              inkBlack.withValues(alpha: 0.88)
            ])))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(children: [
            // The banner hangs from the top edge, large.
            SizedBox(
                width: 112,
                height: 224,
                child: FittedBox(
                    fit: BoxFit.fill,
                    child: PixelBanner(id: clanBannerId('mire')!, scale: 1))),
            const SizedBox(height: 10),
            Text('The $clan',
                textAlign: TextAlign.center,
                style: _p(12, inkGrey, w: FontWeight.w700)),
            Text('Swear to the $clan?',
                textAlign: TextAlign.center, style: _d(26, inkPaper)),
            const SizedBox(height: 8),
            Text(lore, textAlign: TextAlign.center, style: _p(13, inkPaper)),
            const SizedBox(height: 14),
            _Gains(dieId: dieId, dieName: dieName, faces: faces),
            const Spacer(),
            _buttons(clan),
          ]),
        ),
      ]),
    );
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  for (final width in [412.0, 360.0]) {
    for (final v in ['A', 'B']) {
      testWidgets('oath $v at ${width.toInt()}', skip: shots == null,
          (tester) async {
        await tester.runAsync(loadAppFonts);
        SharedPreferences.setMockInitialValues({'app_language': 'en'});
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        await tester.pumpWidget(ProviderScope(
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
                home: Scaffold(
                    appBar: AppBar(title: const Text('The Ashen Tower')),
                    body: _Oath(v))),
          ),
        ));
        for (var i = 0; i < 24; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 60)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.runAsync(() async {
          final b =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await b.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/oath-$v-${width.toInt()}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}
