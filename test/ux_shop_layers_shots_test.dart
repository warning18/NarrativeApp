// PICTURES ONLY (UX_SHOTS=<folder>): the shop screen as layers, a proposal:
// background plate (the shop's place) -> shopkeeper NPC -> stall in front,
// then the keeper's line and the wares list under it. Stalls come from Art's
// test (STALLS=<folder with stall_*.png>); only the forge and the apothecary
// exist, the other shops borrow one of them here. Names and prices in the
// wares list are samples. English 412 and French 360.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'support/fonts.dart';

final _stalls = Platform.environment['STALLS'] ?? '';

class _Shop {
  const _Shop(this.id, this.nameEn, this.nameFr, this.scene, this.npc,
      this.stall, this.lineEn, this.lineFr, this.wares);
  final String id, nameEn, nameFr, scene, npc, stall, lineEn, lineFr;
  final List<(String, String, int)> wares; // icon id, name, price
}

const _shops = [
  _Shop(
      'weaponsmith_forge',
      'The Weaponsmith’s Forge',
      'La Forge de l’Armurier',
      'saltmouth_yard',
      'weaponsmith_forge',
      'stall_forge',
      'Steel for honest coin. Every blade here was asked for before it was forged.',
      'De l’acier contre de l’argent honnête. Chaque lame ici a été demandée avant d’être forgée.',
      [
        ('sword_t3', 'Iron Sword', 45),
        ('shield_t3', 'Round Shield', 38),
        ('dagger_t3', 'Hooked Dagger', 30)
      ]),
  _Shop(
      'apothecary_row',
      'Apothecary Row',
      'La Rue des Apothicaires',
      'saltmouth_tern_row',
      'apothecary_row',
      'stall_apothecary',
      'Fever-bark from the Courts, boiled honest. Tell me what hurts, not what you want.',
      'De l’écorce-fièvre des Cours, bouillie honnêtement. Dites-moi ce qui fait mal.',
      [
        ('potion_minor', 'Minor Potion', 12),
        ('antidote', 'Antidote', 10),
        ('potion_major', 'Major Potion', 28)
      ]),
  _Shop(
      'ossuary_relics',
      'The Ossuary Trade',
      'Le Comptoir de l’Ossuaire',
      'drowned_cloister_ossuary',
      'ossuary_relics',
      'stall_forge',
      'Second-hand steel off a shelf of skulls. I stopped asking where it came from.',
      'De l’acier d’occasion sur un rayon de crânes. J’ai cessé de demander d’où ça vient.',
      [
        ('saint_reliquary', 'Saint’s Reliquary', 90),
        ('plate_emberproof', 'Emberproof Plate', 120),
        ('potion_minor', 'Minor Potion', 12)
      ]),
  _Shop(
      'last_lantern',
      'The Last Lantern',
      'La Dernière Lanterne',
      'reliquary_quarter',
      'last_lantern',
      'stall_apothecary',
      'The last stall lit this close to the tear. Buy what keeps you breathing.',
      'Le dernier étal allumé si près de la déchirure. Achetez ce qui vous garde en vie.',
      [
        ('harborwatch_lantern', 'Harbourwatch Lantern', 70),
        ('potion_major', 'Major Potion', 28),
        ('antidote', 'Antidote', 10)
      ]),
];

TextStyle _display(double s, Color c) => TextStyle(
    fontFamily: InkFonts.display, fontSize: s, height: 1.05, color: c);
TextStyle _prose(double s, Color c, {bool italic = false}) => TextStyle(
    fontFamily: InkFonts.prose,
    fontSize: s,
    height: 1.25,
    color: c,
    fontStyle: italic ? FontStyle.italic : null);

/// Background -> NPC -> stall, in the stall's own pixels scaled by [k]. The
/// NPC's feet stand at y 52 of the stall (under the counter top at 40), and
/// the stall's bottom sits on the plate's ground line.
Widget _layers(_Shop s, double width, double height) {
  final k = width / 150; // the stall is 96 px of 150: about two thirds
  final stallW = 96 * k, stallH = 64 * k;
  return SizedBox(
    width: width,
    height: height,
    child: Stack(children: [
      Positioned.fill(
          child: Image.asset('assets/visuals/scenes/${s.scene}.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              alignment: Alignment.bottomCenter)),
      Positioned.fill(
          child: ColoredBox(color: inkBlack.withValues(alpha: 0.28))),
      Positioned(
        left: (width - stallW) / 2,
        bottom: height * 0.06,
        width: stallW,
        height: stallH,
        child: Stack(clipBehavior: Clip.none, children: [
          // The NPC: a 64 px frame whose feet are at frame y 56.
          Positioned(
              left: (48 - 32) * k,
              top: (52 - 56) * k,
              width: 64 * k,
              height: 64 * k,
              child: Image.asset('assets/visuals/keepers/${s.npc}.png',
                  fit: BoxFit.fill, filterQuality: FilterQuality.none)),
          Positioned.fill(
              child: Image.file(File('$_stalls/${s.stall}.png'),
                  fit: BoxFit.fill, filterQuality: FilterQuality.none)),
        ]),
      ),
    ]),
  );
}

Widget _screen(_Shop s, double w, bool fr) {
  final line = fr ? s.lineFr : s.lineEn;
  return Container(
    width: w,
    color: inkDeep,
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          height: 44,
          color: inkBlack,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          child: Text(fr ? s.nameFr : s.nameEn, style: _display(20, inkPaper))),
      _layers(s, w, w * 0.52),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        child: Text('“$line”', style: _prose(13, inkPaper, italic: true)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
        child: Column(children: [
          for (final (id, name, price) in s.wares)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: inkBlack,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: inkGrey, width: 1)),
              child: Row(children: [
                Image.asset('assets/icons/items/$id.png',
                    width: 32,
                    height: 32,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 32, height: 32)),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: _prose(14, inkPaper))),
                Text('$price', style: _prose(14, inkPaper)),
              ]),
            ),
        ]),
      ),
    ]),
  );
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  testWidgets('shop layers', skip: shots == null || _stalls.isEmpty, (t) async {
    await t.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    addTearDown(t.view.reset);
    for (final (name, w, fr) in [('en', 412.0, false), ('fr', 360.0, true)]) {
      final key = GlobalKey();
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = Size(w * 4 + 60, 700);
      await t.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          color: const Color(0xFF05060A),
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: Container(
                color: const Color(0xFF05060A),
                padding: const EdgeInsets.all(10),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final s in _shops) ...[
                        _screen(s, w, fr),
                        const SizedBox(width: 10),
                      ],
                    ]),
              ),
            ),
          ),
        ),
      ));
      for (var i = 0; i < 6; i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)));
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(t.takeException(), isNull);
      await t.runAsync(() async {
        final r =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await r.toImage(pixelRatio: 1.5);
        final b = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/shops-$name.png')
            .writeAsBytesSync(b!.buffer.asUint8List());
      });
      await t.pumpWidget(const SizedBox());
    }
  });
}
