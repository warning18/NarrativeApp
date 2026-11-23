// How a foe's weakness could read on its fight block (UX_SHOTS=<folder>),
// pictures only. The user keeps the x3 and wants each foe's weak element on
// its block, and a hint when the hero's die matches. Real data: enemies.json
// (weakTo and resists per foe: the Tear-Herald weak to Light, the Inquisition
// Warden to Electricity, the Bone Warden to Earth and Light) on the real
// FightBlock (the C block, v1.9xx) and the real heads. Mock only: nothing here
// is used by the app.
//   A  the marks as gems on the head's top corners (beside armour and damage);
//   B  a mark on the nameplate, on the plate's right (the rank sits left of it);
//   C  a chip in the block's chip row ("Light x3", "Void x1/2");
//   hint: the hero's dice with the one that matches the aimed foe lit and
//   tagged x3, and the foe's mark ringed.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/enemy_intent.dart'
    show enemyResistances, enemyWeaknesses, weaknessMultiplier;
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/palette.dart';
import 'package:narrative_data_app/theme/pixel_chip.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/enemy_groups.dart';
import 'package:narrative_data_app/widgets/fight_block.dart';
import 'package:narrative_data_app/widgets/head_avatar.dart';

import 'support/fonts.dart';

late Map<String, dynamic> _enemies;

/// The element's mark (the app has none for Light and Ice yet: the mock draws
/// them) and its colour.
IconData _icon(String e) => switch (e) {
      'Fire' => Icons.local_fire_department,
      'Wind' => Icons.air,
      'Earth' => Icons.terrain,
      'Water' => Icons.water_drop,
      'Electricity' => Icons.bolt,
      'Void' => Icons.blur_on,
      'Light' => Icons.wb_sunny,
      'Ice' => Icons.ac_unit,
      _ => Icons.circle_outlined,
    };

Color _tint(String e) => switch (e) {
      'Fire' => const Color(0xFFE4572E),
      'Wind' => const Color(0xFF7FB7A4),
      'Earth' => const Color(0xFFB07A3B),
      'Water' => const Color(0xFF3D8FD6),
      'Electricity' => const Color(0xFFF2C230),
      'Void' => const Color(0xFF9A6BD1),
      'Light' => const Color(0xFFF3E3A0),
      'Ice' => const Color(0xFF8FD8E8),
      _ => Palette.slate,
    };

/// A small pixel-cornered mark: the element's icon, its colour, a value.
Widget _mark(BuildContext c, String element, String value,
    {required bool weak, double size = 19, bool ring = false}) {
  final scheme = Theme.of(c).colorScheme;
  final frame = weak ? Palette.goodDeep : Palette.slate;
  return Container(
    height: size,
    padding: const EdgeInsets.symmetric(horizontal: 3),
    decoration: ShapeDecoration(
      color: scheme.surface,
      shape: PixelChipBorder(
          side: BorderSide(
              color: ring ? Palette.goldDark : frame, width: ring ? 2.5 : 1.5),
          step: 2,
          steps: 2),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(_icon(element), size: 11, color: _tint(element)),
      const SizedBox(width: 1),
      Text(value,
          style: TextStyle(
              fontFamily: InkFonts.prose,
              fontWeight: FontWeight.w700,
              fontSize: 9,
              height: 1,
              color: weak ? Palette.goodDeep : scheme.onSurfaceVariant)),
    ]),
  );
}

String get _x3 => '×${weaknessMultiplier.round()}';

class _Foe {
  _Foe(this.id) : data = _enemies[id] as Map<String, dynamic>;
  final String id;
  final Map<String, dynamic> data;
  String get name => data['enemyName'] as String;
  List<String> get weak => enemyWeaknesses(data);
  List<String> get resist => enemyResistances(data);
}

Widget _bar(BuildContext c, _Foe foe) {
  final hp = (foe.data['maxHealth'] as num).toInt();
  return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: const LinearProgressIndicator(
              value: 1, minHeight: 7, color: Palette.hot),
        ),
        const SizedBox(height: 1),
        Text('$hp / $hp',
            style: TextStyle(
                fontFamily: InkFonts.system,
                fontSize: 8,
                color: Theme.of(c).colorScheme.onSurfaceVariant)),
      ]);
}

enum _Option { baseline, gems, plate, chips }

Widget _block(BuildContext c, _Foe foe, _Option option,
    {String? aimedMatch, bool boss = false}) {
  final group = groupLookOf(foe.data);
  final scheme = Theme.of(c).colorScheme;
  final armor = (foe.data['guile'] as num?)?.toInt();
  final damage = (foe.data['damage'] as num?)?.toInt();
  Widget head = HeadAvatar(id: foe.id, name: foe.name, size: 32);
  if (option == _Option.gems) {
    // A mark on each top corner of the head: what it is weak to, resists.
    head = Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(child: head),
      Positioned(
        right: -7,
        top: -3,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final e in foe.weak)
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: _mark(c, e, _x3,
                  weak: true,
                  size: 15,
                  ring: aimedMatch != null && aimedMatch == e),
            ),
        ]),
      ),
      Positioned(
        left: -7,
        top: -3,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final e in foe.resist)
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: _mark(c, e, '×½', weak: false, size: 15),
            ),
        ]),
      ),
    ]);
  }
  final chips = <Widget>[
    if (option == _Option.chips) ...[
      for (final e in foe.weak)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _mark(c, e, _x3,
              weak: true, ring: aimedMatch != null && aimedMatch == e),
        ),
      for (final e in foe.resist)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _mark(c, e, '×½', weak: false),
        ),
    ],
  ];
  final block = FightBlock(
    name: foe.name,
    plateColor: group.color,
    group: group,
    rank: boss ? FightRank.boss : FightRank.normal,
    fill: scheme.errorContainer.withValues(alpha: 0.18),
    head: head,
    armor: armor != null && armor > 0 ? armor : null,
    damage: damage,
    bar: _bar(c, foe),
    chips: chips,
  );
  if (option != _Option.plate) return block;
  // On the nameplate's right: the weak marks, the resists after, in the plate.
  return Stack(children: [
    block,
    Positioned(
      top: 3,
      right: boss ? 52 : 5,
      height: FightBlock.plateHeight,
      child: Center(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final e in foe.weak)
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: _mark(c, e, _x3,
                  weak: true,
                  size: 15,
                  ring: aimedMatch != null && aimedMatch == e),
            ),
          for (final e in foe.resist)
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: _mark(c, e, '×½', weak: false, size: 15),
            ),
        ]),
      ),
    ),
  ]);
}

TextStyle _sys(BuildContext c, double s, {Color? color}) => TextStyle(
    fontFamily: InkFonts.system,
    fontSize: s,
    height: 1.2,
    color: color ?? Theme.of(c).colorScheme.onSurfaceVariant);

Widget _section(BuildContext c, String title, String note, List<Widget> kids) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title,
            style: TextStyle(
                fontFamily: InkFonts.display,
                fontSize: 17,
                color: Theme.of(c).colorScheme.onSurface)),
        Text(note, style: _sys(c, 10)),
        const SizedBox(height: 6),
        for (final k in kids)
          Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SizedBox(height: 70, child: k)),
      ]),
    );

/// The hero's dice: a face of each element the party holds, the one matching
/// the aimed foe lit and tagged with its multiplier.
Widget _dice(BuildContext c, {required String aimedWeak, required String foe}) {
  final scheme = Theme.of(c).colorScheme;
  Widget die(String element, int face, {bool hit = false}) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 52,
              height: 52,
              decoration: ShapeDecoration(
                color: hit
                    ? Palette.goodDeep.withValues(alpha: 0.18)
                    : scheme.surface,
                shape: PixelChipBorder(
                    side: BorderSide(
                        color: hit ? Palette.goodDeep : scheme.outlineVariant,
                        width: hit ? 3 : 1.5),
                    step: 3,
                    steps: 3),
              ),
              alignment: Alignment.center,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(_icon(element), size: 18, color: _tint(element)),
                Text('$face',
                    style: TextStyle(
                        fontFamily: InkFonts.display,
                        fontSize: 18,
                        height: 1,
                        color: scheme.onSurface)),
              ]),
            ),
            if (hit)
              Positioned(
                right: -8,
                top: -8,
                child: _mark(c, element, _x3, weak: true, size: 17),
              ),
          ]),
          const SizedBox(height: 4),
          Text(element, style: _sys(c, 9)),
        ],
      );
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: ShapeDecoration(
      color: scheme.surfaceContainer,
      shape: PixelChipBorder(
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          step: 3,
          steps: 3),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        die('Fire', 4),
        die(aimedWeak, 5, hit: true),
        die('Void', 3),
        die('None', 6),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Icon(_icon(aimedWeak), size: 14, color: Palette.goodDeep),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
              'Your $aimedWeak die hits $foe $_x3: it is weak to $aimedWeak.',
              style: TextStyle(
                  fontFamily: InkFonts.prose,
                  fontStyle: FontStyle.italic,
                  fontSize: 13.5,
                  height: 1.3,
                  color: scheme.onSurface)),
        ),
      ]),
    ]),
  );
}

Widget _page(BuildContext c, List<Widget> children) => Scaffold(
      body: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        children: children,
      ),
    );

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('how a weakness reads on the fight block', skip: shots == null,
      (tester) async {
    await tester.runAsync(loadAppFonts);
    _enemies =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    Directory(shots!).createSync(recursive: true);
    final herald = _Foe('tear_herald');
    final warden = _Foe('inquisition_warden');
    final bone = _Foe('bone_warden');
    for (final dark in [true, false]) {
      tester.view.physicalSize = const Size(360, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      Future<void> shoot(String name, Widget Function(BuildContext) build,
          {double height = 1500}) async {
        tester.view.physicalSize = Size(360, height);
        await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            theme: buildAppTheme(AppPalette.stitchedInk
                .schemeFor(dark ? Brightness.dark : Brightness.light)),
            home: Builder(builder: build),
          ),
        ));
        // The heads are images: give them real time to load.
        for (var i = 0; i < 3; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 400)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/$name-${dark ? 'dark' : 'light'}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }

      Widget options(BuildContext c, List<(String, String, _Option)> rows,
          {String? aimed}) {
        return _page(c, [
          for (final (title, note, option) in rows)
            _section(c, title, note, [
              _block(c, herald, option, boss: true, aimedMatch: aimed),
              _block(c, warden, option),
              _block(c, bone, option),
            ]),
        ]);
      }

      await shoot(
          'weakness-options',
          (c) => options(c, const [
                (
                  'Now',
                  'a foe shows what it is weak to only once learned',
                  _Option.baseline
                ),
                (
                  'A · on the head',
                  'the weak element top right (×3), the resisted one top left (×½)',
                  _Option.gems
                ),
              ]),
          height: 1000);
      await shoot(
          'weakness-options-2',
          (c) => options(c, const [
                (
                  'B · on the nameplate',
                  'marks in the plate, after the name (the rank stays right)',
                  _Option.plate
                ),
                (
                  'C · in the chip row',
                  'the marks sit with the statuses, under the health bar',
                  _Option.chips
                ),
              ]),
          height: 1000);
      await shoot(
          'weakness-hint',
          (c) => _page(c, [
                _section(
                    c,
                    'The die that matches',
                    'the hero\'s die for the aimed foe, lit, with ×3 on it; the foe\'s mark ringed',
                    [
                      _block(c, herald, _Option.plate,
                          boss: true, aimedMatch: 'Light'),
                      _block(c, herald, _Option.chips,
                          boss: true, aimedMatch: 'Light'),
                    ]),
                _dice(c, aimedWeak: 'Light', foe: herald.name),
              ]),
          height: 640);
    }
  });
}
